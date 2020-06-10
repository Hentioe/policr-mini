defmodule PolicrMini.EctoEnums do
  import EctoEnum

  defenum ChatTypeEnum,
    private: "private",
    group: "group",
    supergroup: "supergroup",
    channel: "channel"

  defenum VerificationModeEnum, image: 0, custom: 1
  defenum VerificationStatusEnum, waiting: 0, passed: 1, timeout: 2, wronged: 3
  defenum VerificationEntranceEnum, unity: 0, independent: 1
  defenum VerificationOccasionEnum, private: 0, public: 1
  defenum KillingMethodEnum, ban: 0, kick: 1
end
