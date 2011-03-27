#include '../include/inc_rk4.h'
#include '../include/inc_atom.h'
#include '../include/inc_misc.h'
#ifdef MISC_PLOT
#include '../include/inc_plot_rk4.h'
#endif

subroutine rk4_re( t0_, tp_, x0_, vx0_, z0_, vz0_, f, ierr, W, px, pz, x, z, L, n_pass_x, n_pass_z )

    implicit none;
    integer, parameter:: nt = RK4_NT
    integer, parameter:: ne = RK4_NE
    integer, parameter:: nmax = RK4_NMAX
    double precision, intent(in):: t0_, tp_, x0_, vx0_, z0_, vz0_
    double precision:: eps = RK4_EPS
    external:: f;
    double precision:: t(nt), y(ne,nt)
    double precision:: K1(ne), K2(ne), K3(ne), K4(ne);
    double precision:: h, p, q;
    double precision:: ft, ftt, fy_old(ne), fy(ne, nmax), fyy(ne), fdyy(ne)
    integer:: ie, it, jt, n_sub;
    integer:: n_iter;

    integer, intent(out):: ierr
    double complex, intent(out):: W
    double precision, intent(out):: pz, px

    double precision:: x, vx, z, vz, v2, r, energy, ang, w_tail, L
    double precision:: Ex, Ez, ax, az, t_sub
    double precision:: charge, Ip
    integer:: i;
    double complex, external:: pulse_E_x, pulse_E_z

    integer:: n_pass_x, n_pass_z

    character(len=200):: rk4_plot_file_name
    logical:: file_e;

#ifdef MISC_PRINT
    print*, 'rk4_re(): Initialization of RK4'
    print*, 't0_', t0_, 'tp_', tp_;
    print*, 'x0_', x0_, 'vx0_', vx0_;
    print*, 'z0_', z0_, 'vz0_', vz0_;
#endif

    h = ( tp_ - t0_ ) / ( nt - 1d0 );
    forall( i = 1:nt ) t(i) = t0_ + ( i - 1d0 ) * h;
    y(1,1) = x0_;
    y(2,1) = vx0_;
    y(3,1) = z0_
    y(4,1) = vz0_;



    W = (0d0, 0d0);
    n_pass_x = 0;
    n_pass_z = 0;

#ifdef RK4_PLOT_TRAJ

    inquire( file=RK4_TRAJ_QUEU_FILE_NAME, exist=file_e )

    if( file_e ) then
        open( RK4_TRAJ_QUEU_FILE_ID, file=RK4_TRAJ_QUEU_FILE_NAME )
        read( RK4_TRAJ_QUEU_FILE_ID, '(a)'), rk4_plot_file_name
        close( RK4_TRAJ_QUEU_FILE_ID )
    else
        rk4_plot_file_name = RK4_TRAJ_PLOT_FILE_NAME;
    end if
    open( RK4_TRAJ_PLOT_FILE_ID, file = trim(rk4_plot_file_name) )

#endif

    do it = 2, nt

        y(:,it) = 0d0;
        fy_old(:) = 0d0;

        n_sub = 2;
        h = ( t(it) - t(it-1) ) / ( n_sub - 1d0 );
        n_iter = 0;

        ! if the precision is not satisified, halve the step length and iterate
        do while( 1 )
            if ( n_sub > nmax ) then
                ierr = 1; ! too many steps still can't reach desired precision
                return;        
            end if

            fy(:,1) = y(:,it-1)
            ft = t(it-1);

            do jt = 2, n_sub
                ftt = ft; 
                fyy(:) = fy(:,jt-1);
                call f( ne, ftt, fyy, fdyy );
                k1(:) = fdyy(:);

                ftt = ft + h / 2d0;
                fyy(:) = fy(:,jt-1) + h * k1(:) / 2d0;
                call f( ne, ftt, fyy, fdyy );
                k2(:) = fdyy(:);

                fyy(:) = fy(:,jt-1) + h * k2(:) / 2d0;
                call f( ne, ftt, fyy, fdyy );
                k3(:) = fdyy(:);

                ftt = ft + h;
                fyy(:) = fy(:,jt-1) + h * K3(:);
                call f( ne, ftt, fyy, fdyy );
                K4(:) = fdyy(:);

                fy(:,jt) = fy(:,jt-1) + &
                      h * (K1(:) + 2d0 * ( K2(:) + K3(:) ) + K4(:) ) / 6d0;

                ft = ft + h;
            end do

            ! at least two times of iterations are needed
            ! to verify the accuracy of the calculation

            p = 1d0;
            
            if( n_iter > 1 ) then

                p = maxval( dabs( fy_old(:) - fy(:, n_sub)) );

            end if

            fy_old(:) = fy(:,n_sub);

            if( p < eps ) then

#ifdef RK4_PLOT_TRAJ

                x = fy(1,n_sub);
                vx = fy(2,n_sub);
                z = fy(3,n_sub);
                vz = fy(4,n_sub);
                write( RK4_TRAJ_PLOT_FILE_ID, '(5(e15.8,2x))' ), &
                      t(it-1), x, vx, z, vz;
#endif

                charge = ATOM_CHARGE_Z;
                Ip = IONIZATION_IP;


                ! calculate the action W
                do i = 2, n_sub

                    if( fy(1,i-1) * fy(1,i) < 0 ) n_pass_x = n_pass_x + 1;
                    if( fy(3,i-1) * fy(3,i) < 0 ) n_pass_z = n_pass_z + 1;

                    x = ( fy(1,i-1) + fy(1,i) ) / 2d0;
                    vx = ( fy(2,i-1) + fy(2,i) ) / 2d0;
                    z = ( fy(3,i-1) + fy(3,i) ) / 2d0;
                    vz = ( fy(4,i-1) + fy(4,i) ) / 2d0;
                    v2 = vz*vz + vx*vx;
                    r = dsqrt( x*x + z*z );

                    ! if the electron get too close to the core
                    if( r < RK4_R_THRESHOLD ) then

                        ierr = 4; ! high-order term we cannot handle currently
                        return;

                    end if

                    if( REPRESENTATION_OPT == 'S' ) then

                        energy = 0.5d0 * v2 - charge / r;

                    elseif( REPRESENTATION_OPT == 'W' ) then

                        t_sub = t(it-1) + (i-1.5d0) * h;
                        Ex = dreal( pulse_E_x( dcmplx(t_sub) ) );
                        Ez = dreal( pulse_E_z( dcmplx(t_sub) ) );
                        ax = -Ex - charge * x / r**3;
                        az = -Ez - charge * z / r**3;
                        energy = 0.5d0 * v2 - charge / r + Ex * x + Ez * z + ax * x + az * z;

                    end if

                    W = W + dcmplx( ( energy + Ip ) * h, 0d0 );
                end do

                exit

            else

                h = h / 2d0;
                n_sub = n_sub + n_sub - 1;
                n_iter = n_iter + 1;

            end if

        end do
        ! we have finished one desired interval in the array,
        ! then go to the next interval

#if MISC_PRINT > 2
        write(*,'(a,i6,a,i6)'), 'number of iteration for sub-step ', &
              it, ': ', n_iter - 1 ;
#endif
        y(:,it) = fy_old(:);

    end do

    x = y(1,nt);
    vx = y(2,nt);
    z = y(3,nt);
    vz = y(4,nt);

    ! calculate asymptotic momentum
    call coulomb_tail( z, x, vz, vx, charge, L, pz, px, w_tail, ierr );

    ! W_cen for the W-representation
    if( REPRESENTATION_OPT == 'W' ) then
        w = w + dcmplx(w_tail, 0d0);
    end if

#ifdef RK4_PLOT_TRAJ
    close( RK4_TRAJ_PLOT_FILE_ID );
#endif

    return;
end subroutine rk4_re
