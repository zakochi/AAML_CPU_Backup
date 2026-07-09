#include "model_profile.h"

#include "platform_config.h"

const ModelProfile* model_profile_get(void) {
  static const ModelProfile kProfile = {
      "vww_96",
      "zero input",
      "verification skipped",
      0,
      0,
      0,
      0,
      0,
      0,
      MODEL_TOLERANCE,
  };
  return &kProfile;
}
