#ifndef PLATFORM_SW_APP_MODEL_PROFILE_H_
#define PLATFORM_SW_APP_MODEL_PROFILE_H_

#include <stddef.h>
#include <stdint.h>

#include "tensorflow/lite/c/common.h"

typedef void (*ModelPrepareInputFn)(TfLiteTensor* input);
typedef void (*ModelVerifyOutputFn)(const TfLiteTensor* output);

struct ModelProfile {
  const char* name;
  const char* input_name;
  const char* output_name;
  ModelPrepareInputFn prepare_input;
  ModelVerifyOutputFn verify_output;
  const int8_t* input_data;
  size_t input_bytes;
  const int8_t* expected_output;
  size_t expected_output_bytes;
  int tolerance;
};

const ModelProfile* model_profile_get(void);

#endif  // PLATFORM_SW_APP_MODEL_PROFILE_H_
