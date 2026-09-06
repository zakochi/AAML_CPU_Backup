#include "tflm_runner.h"

#include <stdint.h>
#include <stdio.h>

#include "model_data.h"
#include "model_io.h"
#include "perf.h"
#include "platform_config.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/schema/schema_generated.h"
#include "tflm_ops.h"

#ifndef TENSOR_ARENA_SIZE
#define TENSOR_ARENA_SIZE PLATFORM_DEFAULT_TENSOR_ARENA_SIZE
#endif

#ifndef MODEL_NAME
#define MODEL_NAME "unknown"
#endif

namespace {

alignas(16) uint8_t tensor_arena[TENSOR_ARENA_SIZE];

void print_duration(uint64_t cycles) {
  printf("Cycles: ");
  perf_print_cycles(cycles);
  putchar('\n');

  printf("Time (70000000 Hz): ");
  perf_print_time_ms(cycles);
}

}  // namespace

void tflm_run_inference(void) {
  printf("=== TFLM Functional Verification ===\n");

  printf("Model: %s (%u bytes)\n",
         MODEL_NAME,
         (unsigned)g_model_len);

  printf("Tensor arena: %u bytes\n",
         (unsigned)sizeof(tensor_arena));

  /*
   * Print model/input profile information.
   *
   * Expected format:
   * Profile: mobile_vit_xxs
   * Input profile: MobileViT XXS Zeros Input Profile
   * Output profile: verification skipped, tolerance=2
   */
  model_io_print_profile();

  const tflite::Model* model = tflite::GetModel(g_model);

  if (model == nullptr) {
    printf("Failed to load model.\n");
    return;
  }

  if (model->version() != TFLITE_SCHEMA_VERSION) {
    printf("Model schema mismatch: got %d, expected %d\n",
           model->version(),
           TFLITE_SCHEMA_VERSION);
    return;
  }

  ProjectOpResolver resolver;
  tflm_register_project_ops(&resolver);

  tflite::MicroInterpreter interpreter(
      model,
      resolver,
      tensor_arena,
      sizeof(tensor_arena));

  if (interpreter.AllocateTensors() != kTfLiteOk) {
    printf("AllocateTensors failed.\n");
    return;
  }

  TfLiteTensor* input = interpreter.input(0);
  TfLiteTensor* output = interpreter.output(0);

  if (input == nullptr || output == nullptr) {
    printf("Model tensors are not available.\n");
    return;
  }

  /*
   * Prepare input first, then print its information.
   *
   * Expected:
   * input bytes=49152 type=9
   */
  model_io_prepare_input(input);

  printf("Running inference...\n");

  uint64_t start_cycles = perf_get_mcycle64();

  TfLiteStatus status = interpreter.Invoke();

  uint64_t cycles = perf_get_mcycle64() - start_cycles;

  if (status != kTfLiteOk) {
    printf("Invoke failed.\n");
    print_duration(cycles);
    return;
  }

  printf("Inference complete.\n");
  
  printf("Output (%u bytes):\n", (unsigned)output->bytes);
  
  const int8_t* output_data = output->data.int8;
  for (unsigned i = 0; i < output->bytes; ++i) {
    printf("%u : %d,\n", i, (int)output_data[i]);
  }
  
  model_io_verify_output(output);
  
  print_duration(cycles);

}
