import 'dart:math';

double convertProgressForUnreal(double x) {
  if (x < 1e6) {
    double logValue = log(x) / ln10;
    return 1 - 1 / pow(2, (6 - logValue));
  } else {
    return 0;
  }
}
