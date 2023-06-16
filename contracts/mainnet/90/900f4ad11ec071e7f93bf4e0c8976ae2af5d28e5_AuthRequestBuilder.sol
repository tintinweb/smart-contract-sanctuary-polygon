// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Structs.sol";

contract AuthRequestBuilder {
  // default values for Auth Request
  bool public constant DEFAULT_AUTH_REQUEST_IS_ANON = false;
  uint256 public constant DEFAULT_AUTH_REQUEST_USER_ID = 0;
  bool public constant DEFAULT_AUTH_REQUEST_IS_OPTIONAL = false;
  bytes public constant DEFAULT_AUTH_REQUEST_EXTRA_DATA = "";

  error InvalidUserIdAndIsSelectableByUserAuthType();
  error InvalidUserIdAndAuthType();

  function build(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bool isOptional,
    bool isSelectableByUser,
    bytes memory extraData
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: userId,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: extraData
      });
  }

  function build(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bytes memory extraData
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: userId,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: extraData
      });
  }

  function build(AuthType authType) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: DEFAULT_AUTH_REQUEST_USER_ID,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(AuthType authType, bool isAnon) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: DEFAULT_AUTH_REQUEST_USER_ID,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(AuthType authType, uint256 userId) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: userId,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(
    AuthType authType,
    bytes memory extraData
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: DEFAULT_AUTH_REQUEST_USER_ID,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: extraData
      });
  }

  function build(
    AuthType authType,
    bool isAnon,
    uint256 userId
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: userId,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(
    AuthType authType,
    bool isAnon,
    bytes memory extraData
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: DEFAULT_AUTH_REQUEST_USER_ID,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: extraData
      });
  }

  function build(
    AuthType authType,
    uint256 userId,
    bytes memory extraData
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: userId,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: extraData
      });
  }

  // allow dev to choose for isOptional
  // the user is ask to choose isSelectableByUser to avoid the function signature collision
  // between build(AuthType authType, bool isOptional) and build(AuthType authType, bool isAnon)

  function build(
    AuthType authType,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: DEFAULT_AUTH_REQUEST_USER_ID,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(
    AuthType authType,
    bool isOptional,
    bool isSelectableByUser,
    uint256 userId
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: userId,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  // the user is ask to choose isSelectableByUser to avoid the function signature collision
  // between build(AuthType authType, bool isAnon, bool isOptional) and build(AuthType authType, bool isOptional, bool isSelectableByUser)

  function build(
    AuthType authType,
    bool isAnon,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: DEFAULT_AUTH_REQUEST_USER_ID,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(
    AuthType authType,
    uint256 userId,
    bool isOptional
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: userId,
        isOptional: isOptional,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bool isOptional
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: userId,
        isOptional: isOptional,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function _build(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bool isOptional,
    bytes memory extraData
  ) internal pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: userId,
        isOptional: isOptional,
        isSelectableByUser: _authIsSelectableDefaultValue(authType, userId),
        extraData: extraData
      });
  }

  function _build(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bool isOptional,
    bool isSelectableByUser,
    bytes memory extraData
  ) internal pure returns (AuthRequest memory) {
    // When `userId` is 0, it means the app does not require a specific auth account and the user needs
    // to choose the account they want to use for the app.
    // When `isSelectableByUser` is true, the user can select the account they want to use.
    // The combination of `userId = 0` and `isSelectableByUser = false` does not make sense and should not be used.
    // If this combination is detected, the function will revert with an error.
    if (authType != AuthType.VAULT && userId == 0 && isSelectableByUser == false) {
      revert InvalidUserIdAndIsSelectableByUserAuthType();
    }
    // When requesting an authType VAULT, the `userId` must be 0 and isSelectableByUser must be true.
    if (authType == AuthType.VAULT && userId != 0 && isSelectableByUser == false) {
      revert InvalidUserIdAndAuthType();
    }
    return
      AuthRequest({
        authType: authType,
        isAnon: isAnon,
        userId: userId,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: extraData
      });
  }

  function _authIsSelectableDefaultValue(
    AuthType authType,
    uint256 requestedUserId
  ) internal pure returns (bool) {
    // isSelectableByUser value should always be false in case of VAULT authType.
    // This is because the user can't select the account they want to use for the app.
    // the userId = Hash(VaultSecret, AppId) in the case of VAULT authType.
    if (authType == AuthType.VAULT) {
      return false;
    }
    // When `requestedUserId` is 0, it means no specific auth account is requested by the app,
    // so we want the default value for `isSelectableByUser` to be `true`.
    if (requestedUserId == 0) {
      return true;
    }
    // When `requestedUserId` is not 0, it means a specific auth account is requested by the app,
    // so we want the default value for `isSelectableByUser` to be `false`.
    else {
      return false;
    }
    // However, the dev can still override this default value by setting `isSelectableByUser` to `true`.
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct SismoConnectRequest {
  bytes16 namespace;
  AuthRequest[] auths;
  ClaimRequest[] claims;
  SignatureRequest signature;
}

struct SismoConnectConfig {
  bytes16 appId;
  VaultConfig vault;
}

struct VaultConfig {
  bool isImpersonationMode;
}

struct AuthRequest {
  AuthType authType;
  uint256 userId; // default: 0
  // flags
  bool isAnon; // default: false -> true not supported yet, need to throw if true
  bool isOptional; // default: false
  bool isSelectableByUser; // default: true
  //
  bytes extraData; // default: ""
}

struct ClaimRequest {
  ClaimType claimType; // default: GTE
  bytes16 groupId;
  bytes16 groupTimestamp; // default: bytes16("latest")
  uint256 value; // default: 1
  // flags
  bool isOptional; // default: false
  bool isSelectableByUser; // default: true
  //
  bytes extraData; // default: ""
}

struct SignatureRequest {
  bytes message; // default: "MESSAGE_SELECTED_BY_USER"
  bool isSelectableByUser; // default: false
  bytes extraData; // default: ""
}

enum AuthType {
  VAULT,
  GITHUB,
  TWITTER,
  EVM_ACCOUNT,
  TELEGRAM,
  DISCORD
}

enum ClaimType {
  GTE,
  GT,
  EQ,
  LT,
  LTE
}

struct Auth {
  AuthType authType;
  bool isAnon;
  bool isSelectableByUser;
  uint256 userId;
  bytes extraData;
}

struct Claim {
  ClaimType claimType;
  bytes16 groupId;
  bytes16 groupTimestamp;
  bool isSelectableByUser;
  uint256 value;
  bytes extraData;
}

struct Signature {
  bytes message;
  bytes extraData;
}

struct SismoConnectResponse {
  bytes16 appId;
  bytes16 namespace;
  bytes32 version;
  bytes signedMessage;
  SismoConnectProof[] proofs;
}

struct SismoConnectProof {
  Auth[] auths;
  Claim[] claims;
  bytes32 provingScheme;
  bytes proofData;
  bytes extraData;
}

struct SismoConnectVerifiedResult {
  bytes16 appId;
  bytes16 namespace;
  bytes32 version;
  VerifiedAuth[] auths;
  VerifiedClaim[] claims;
  bytes signedMessage;
}

struct VerifiedAuth {
  AuthType authType;
  bool isAnon;
  uint256 userId;
  bytes extraData;
  bytes proofData;
}

struct VerifiedClaim {
  ClaimType claimType;
  bytes16 groupId;
  bytes16 groupTimestamp;
  uint256 value;
  bytes extraData;
  uint256 proofId;
  bytes proofData;
}