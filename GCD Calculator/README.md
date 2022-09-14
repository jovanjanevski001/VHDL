# Greatest Common Denominator (GCD) Calculator

// inputs: go, x, y
// outputs: output, done
// reset values (add any others that you might need)
output = 0;
done = 0;
while(1) {
  // wait for go to start circuit
  while (go == 0);
  done = 0;
  // store inputs in registers
  tmpX = X;
  tmpY = Y;
  // main GCD algorithm
  while (tmpX != tmpY) {
    if (tmpX < tmpY)
      tmpY = tmpY-tmpX;
    else
      tmpX = tmpX-tmpY;
}
  // assign output and assert done
  output = tmpX; 
  done = 1;
  // make sure go has been cleared before starting again
  while (go == 1);
}
