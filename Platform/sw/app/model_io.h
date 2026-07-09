#ifndef PLATFORM_SW_APP_MODEL_IO_H_
#define PLATFORM_SW_APP_MODEL_IO_H_

#include "tensorflow/lite/c/common.h"

void model_io_print_profile(void);
void model_io_prepare_input(TfLiteTensor* input);
void model_io_verify_output(const TfLiteTensor* output);

#endif  // PLATFORM_SW_APP_MODEL_IO_H_
