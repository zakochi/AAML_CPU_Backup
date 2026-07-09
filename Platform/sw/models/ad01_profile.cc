#include "model_profile.h"

#include "ad01_fixture.h"
#include "platform_config.h"

const ModelProfile* model_profile_get(void) {
  static const ModelProfile kProfile = {
      "ad01",
      "ad01 fixture",
      "ad01 golden output",
      0,
      0,
      kAd01InputData,
      sizeof(kAd01InputData),
      kAd01ExpectedOutput,
      sizeof(kAd01ExpectedOutput),
      MODEL_TOLERANCE,
  };
  return &kProfile;
}
