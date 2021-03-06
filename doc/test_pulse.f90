program main
    use mod_pulse, only: set_pulse, set_pulse_t0
    
    implicit none;
    
    double precision:: E0, om, n, xi;
    double complex:: t0, t;
    double complex, external:: pulse_A_z, pulse_E_z, &
          pulse_A_x, pulse_E_x, &
          alpha_z, alpha_x;
    double complex:: Az, Ax, Ez, Ex, alz, alx
    

    E0 = 0.0577;
    om = 0.0663d0;
    n = 2d0;
    xi = 0.6d0;

    t0 = (200d0, 0d0);
    t = (180d0, 20d0);

    call set_pulse( E0, om, n, xi );
    call set_pulse_t0( t0 );
 

    Az = pulse_A_z(t);
    print*, 'pulse_A_z', Az;

    Ax = pulse_A_x(t);
    print*, 'pulse_A_x', Ax;

    Ez = pulse_E_z(t);
    print*, 'pulse_E_z', Ez;
    
    Ex = pulse_E_x(t);
    print*, 'pulse_E_x', Ex;

    alz = alpha_z(t);
    print*, 'alpha_z', alz;
    
    alx = alpha_x(t);
    print*, 'alpha_x', alx;
    
end program main
