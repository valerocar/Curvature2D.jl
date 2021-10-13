# How does it work?

A plane curve can be parametrized as $p(s)=(x(s),y(s))$, where $s$ is the arc-length from the initial point of the curve to $p$.
The unit tangent vector
$$T(s) = \frac{dp}{ds}(s) = \left(\frac{dx}{ds}(s),\frac{dy}{ds}(s)\right)$$
can be written as
$$T(s)=(\cos(\theta(s),\sin(\theta(s))).$$
We have that
$$\kappa=\frac{d\theta}{ds}$$
If we define the normal field $N$ as
$$N=(-\sin(\theta),\cos(\theta))$$
then
$$\frac{dT}{ds} = \kappa N$$
This differential equation can be written as the second order system
$$\frac{d^2x}{ds} = -\kappa y, \frac{d^2y}{ds} = \kappa x$$
To solve these equations we need the initial conditions
$$x(0)=x_0,y(0)=x_0,\frac{dx}{ds}(0)=\cos(\theta_0)\text{ and }\frac{dy}{ds}(0)=\sin(\theta_0).$$
These conditions determine the initial position and orientation of the curve. We use the numerical integrator RK4 to integrate the above equations for $x_0=0,y_0=0$ and $\theta_0=0$.
