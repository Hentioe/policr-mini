defmodule PolicrMini.EctoEnums do
  @moduledoc """
  枚举类型定义。
  """

  import EctoEnum

  defenum ChatTypeEnum,
    private: "private",
    group: "group",
    supergroup: "supergroup",
    channel: "channel"

  defenum VerificationModeEnum, image: 0, custom: 1, arithmetic: 2, initiative: 3
  defenum VerificationStatusEnum, waiting: 0, passed: 1, timeout: 2, wronged: 3, expired: 4
  defenum VerificationEntranceEnum, unity: 0, independent: 1
  defenum VerificationOccasionEnum, private: 0, public: 1
  defenum KillingMethodEnum, ban: 0, kick: 1
  defenum OperationActionEnum, kick: 0, ban: 1
  defenum OperationRoleEnum, system: 0, admin: 1
end
