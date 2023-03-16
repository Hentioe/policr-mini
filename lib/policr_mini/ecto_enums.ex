defmodule PolicrMini.EctoEnums do
  @moduledoc """
  枚举类型定义。
  """

  import EctoEnum

  defenum ChatType,
    private: "private",
    group: "group",
    supergroup: "supergroup",
    channel: "channel"

  defenum VerificationModeEnum, image: 0, custom: 1, arithmetic: 2, initiative: 3

  defenum VerificationStatusEnum,
    waiting: 0,
    passed: 1,
    timeout: 2,
    wronged: 3,
    expired: 4,
    manual_kick: 5,
    manual_ban: 6

  defenum KillingMethodEnum, ban: 0, kick: 1
  defenum OperationActionEnum, kick: 0, ban: 1
  defenum OperationRoleEnum, system: 0, admin: 1
  defenum StatVerificationStatus, passed: 0, timeout: 1, wronged: 2, other: 3
  defenum MentionText, user_id: 0, full_name: 1, mosaic_full_name: 2
  defenum ServiceMessage, joined: 0, lefted: 1
end
