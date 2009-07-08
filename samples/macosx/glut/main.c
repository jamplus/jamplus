#include <stdlib.h>

#include <GLUT/glut.h>

// Code from http://blog.onesadcookie.com/2007/12/xcodeglut-tutorial.html
void display(void)
{
   	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glBegin(GL_QUADS);
    	glVertex2f(-0.75f, -0.75f);
    	glVertex2f( 0.75f, -0.75f);
    	glVertex2f( 0.75f,  0.75f);
    	glVertex2f(-0.75f,  0.75f);
    glEnd();

    glutSwapBuffers();
}

void reshape(int width, int height)
{
    glViewport(0, 0, width, height);
}

void idle(void)
{
    glutPostRedisplay();
}

int main(int argc, char** argv)
{
    glutInit(&argc, argv);
    
    glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH);
    glutInitWindowSize(640, 480);
    
    glutCreateWindow("GLUT Program");
    
    glutDisplayFunc(display);
    glutReshapeFunc(reshape);
    glutIdleFunc(idle);
    
    glutMainLoop();
    return EXIT_SUCCESS;
}
