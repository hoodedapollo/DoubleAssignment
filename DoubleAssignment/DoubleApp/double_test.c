/** \file double_test.c
 * \brief Trigonometry calculations for Double rotation test
 
 Since there is no documentation, we tested that the method of the DoubleControlSDK for the rotation (turnByDegrees) makes the Double rotate by the right angle only if it is within the range (-180;+180)
 For this reason a method was developed that computes the minimum angle beween the initial orientation and the orientation toward the goal.
 To test the validity of the calculation we figured out this test.
 Given an aribitrarily fixed goal position (xf = 2, yf = 2), the initial position is changed across all the domain. If the computed direction is different from the actual direction to be followed an error message is printed. Also if the computed angle the Double must turn is more than 180 degrees an error message is printed. Otherwise the "SUCCESS"message is printed.
 */

#include <stdio.h>      /* printf */
#include <math.h>       /* atan2 */

#define PI 3.14159265

int main ()
{
        double xi,yi,o, xf,yf; 
        double dx, dy, result;
        double moving_dir;

        xf = 2;
        yf =2;
        for(xi = 0; xi < 3.45; xi = xi +0.1)
        {
                for(yi = 0; yi < 4.7; yi = yi + 0.1)
                {
                        for (o = 0; o < 360; o = o +10)
                        {
                                double beta = 360 - o;
                                double alpha = o;
                                dx = xf -xi;
                                dy = yf-yi;
                                double distance = sqrt(pow(dx,2) + pow(dy,2));
                                double theta = atan (dy/dx) * 180 / PI;
                                if (dx <0)
                                {
                                        theta = theta +180;       
                                }
                                if (theta < 0)
                                {
                                        theta = theta + 360;
                                        if (round(theta) == 360) 
                                        {
                                                theta = 0;
                                        }
                                }

                                if(theta<180.0 && beta<180.0 && theta + beta<180.0)
                                {
                                        moving_dir =  (beta + theta);
                                }
                                else if(theta>180.0 && beta>180.0 && theta-alpha>180.0)
                                {
                                        moving_dir = (theta-(alpha + 360));
                                }
                                else 
                                {
                                        moving_dir =  (theta -alpha);
                                }


                                double theta_c = o + moving_dir;
                                if (round(theta_c*100) != round(theta*100) && round(theta_c*100) != round(theta*100) +360*100 &&  round(theta_c*100) != round(theta*100) - 360*100 )
                                {
                                        printf("mismatch between actual theta and calculated theta\n");
                                        printf ("xi: %f, yi: %f dx: %f, dy: %f double initial orientation(alpha): %f \n  theta effettiva: %f \n  theta calcolata: %f\nmoving direction: %f\n", xi, yi, dx, dy, o, theta, theta_c, moving_dir);
                                        return 1;
                                }

                                if (moving_dir > 180)
                                {
                                        printf("moving diraction > 180:\n");
                                        printf ("xi: %f, yi: %f dx: %f, dy: %f double initial orientation(alpha): %f \n  theta effettiva: %f \n  theta calcolata: %f\nmoving direction: %f\n", xi, yi, dx, dy, o, theta, theta_c, moving_dir);
                                        return 1;
                                }
                        }
                }
        }
        printf("SUCCESS\n");
        return 0;
}
