/**
 *Submitted for verification at polygonscan.com on 2022-07-04
*/

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.15.0;

library Bits {
  // Each _WIDTH is the number of Bits given to the
  // particular field. The _BOUNDARY is the bit before
  // the first bit of the field.
  uint8 public constant TEAM_WIDTH = 13;
  uint8 public constant TEAM_BOUNDARY = uint8(256 - TEAM_WIDTH);
  uint8 public constant TYPE_WIDTH = 8;
  uint8 public constant TYPE_BOUNDARY = TEAM_BOUNDARY - TYPE_WIDTH;
  uint8 public constant REQUIREMENT_WIDTH = 3;
  uint8 public constant REQUIREMENT_BOUNDARY = TYPE_BOUNDARY - REQUIREMENT_WIDTH;
  uint8 public constant REPETITION_WIDTH = 3;
  uint8 public constant REPETITION_BOUNDARY = REQUIREMENT_BOUNDARY - REPETITION_WIDTH;
  uint8 public constant UNIQUENESS_WIDTH = 1;
  uint8 public constant UNIQUENESS_BOUNDARY = REPETITION_BOUNDARY - UNIQUENESS_WIDTH;
  uint8 public constant ROLE_WIDTH = 8;
  uint8 public constant ROLE_BOUNDARY = UNIQUENESS_BOUNDARY - ROLE_WIDTH;
  uint8 public constant INTERNAL_WIDTH = 1;
  uint8 public constant INTERNAL_BOUNDARY = ROLE_BOUNDARY - INTERNAL_WIDTH;
  uint8 public constant COUNTER_WIDTH = 32;
  uint256 public constant TEAM_MASK = (2**TEAM_WIDTH - 1) << TEAM_BOUNDARY;
  uint256 public constant TYPE_MASK = (2**TYPE_WIDTH - 1) << TYPE_BOUNDARY;
  uint256 public constant REQUIREMENT_MASK = (2**REQUIREMENT_WIDTH - 1) << REQUIREMENT_BOUNDARY;
  uint256 public constant REPETITION_MASK = (2**REPETITION_WIDTH - 1) << REPETITION_BOUNDARY;
  uint256 public constant UNIQUENESS_MASK = (2**UNIQUENESS_WIDTH - 1) << UNIQUENESS_BOUNDARY;
  uint256 public constant ROLE_MASK = (2**ROLE_WIDTH - 1) << ROLE_BOUNDARY;
  uint256 public constant INTERNAL_MASK = (2**INTERNAL_WIDTH - 1) << INTERNAL_BOUNDARY;
  uint256 public constant COUNTER_MASK = (2**COUNTER_WIDTH - 1);

  // 13 publicity Bits defining groups to which
  // the the token information is accessible

  // Error: Constants of non-value type not yet implemented.
  // uint256[] public constant TEAM = []

  uint256 public constant TEAM_1 = 2**0 << TEAM_BOUNDARY;
  uint256 public constant TEAM_2 = 2**1 << TEAM_BOUNDARY;
  uint256 public constant TEAM_3 = 2**2 << TEAM_BOUNDARY;
  uint256 public constant TEAM_4 = 2**3 << TEAM_BOUNDARY;
  uint256 public constant TEAM_5 = 2**4 << TEAM_BOUNDARY;
  uint256 public constant TEAM_6 = 2**5 << TEAM_BOUNDARY;
  uint256 public constant TEAM_7 = 2**6 << TEAM_BOUNDARY;
  uint256 public constant TEAM_8 = 2**7 << TEAM_BOUNDARY;
  uint256 public constant TEAM_9 = 2**8 << TEAM_BOUNDARY;
  uint256 public constant TEAM_A = 2**9 << TEAM_BOUNDARY;
  uint256 public constant TEAM_B = 2**10 << TEAM_BOUNDARY;
  uint256 public constant TEAM_C = 2**11 << TEAM_BOUNDARY;
  uint256 public constant TEAM_D = 2**12 << TEAM_BOUNDARY;

  // There are four modes for how the publicity
  // is interpreted.
  uint256 public constant REQUIRE_ALL   = 1 << REQUIREMENT_BOUNDARY;
  uint256 public constant REQUIRE_NONE  = 2 << REQUIREMENT_BOUNDARY;
  uint256 public constant REQUIRE_ONE   = 3 << REQUIREMENT_BOUNDARY;
  uint256 public constant USE_ONCE      = 1 << REPETITION_BOUNDARY;
  uint256 public constant USE_UNLIMITED = 2 << REPETITION_BOUNDARY;
  uint256 public constant USE_UNTIL     = 3 << REPETITION_BOUNDARY;
  uint256 public constant USE_AFTER     = 4 << REPETITION_BOUNDARY;
  uint256 public constant UNIQUE        = 1 << UNIQUENESS_BOUNDARY;


  // Gating tokens control access to contract
  // functionality.
  uint256 public constant GATING_TYPE        = 1 << TYPE_BOUNDARY;
  // Membership tokens represent being given
  // access to a team's information.
  uint256 public constant MEMBERSHIP_TYPE    = 2 << TYPE_BOUNDARY;
  // Address tokens have a lower 160 Bits which
  // correspond to an Ethereum address.
  uint256 public constant ADDRESS_TYPE       = 3 << TYPE_BOUNDARY; // ¿?
  // Time tokens are divisible tokens to be
  // distributed in response to activities
  // that require time in proportion to that
  // time. I.e. 1 for 1 hour of pair programming.
  uint256 public constant RECORDED_TIME_TYPE = 4 << TYPE_BOUNDARY;
  // Whereas recorded time is directly viewable,
  // vouched time is represented by a summary of what
  // was accomplished and how long it took. As with
  // recorded time, the token is distributed proportionally
  // to the time spent.
  uint256 public constant VOUCHED_TIME_TYPE  = 5 << TYPE_BOUNDARY;
  // A recording is a reactable event.
  uint256 public constant RECORDING_TYPE     = 6 << TYPE_BOUNDARY;
  // A review is a set of reactions to a recording.
  uint256 public constant REVIEW_TYPE        = 7 << TYPE_BOUNDARY;
  // 20 bytes of a hash of a reaction, be it a word or
  // image along with a signed byte representing the weight.
  // This may be too much info for a token or even to have in
  // the contract…
  uint256 public constant REACTION_TYPE      = 8 << TYPE_BOUNDARY;
  // Vanilla NFTs are created by using `create` to reserve
  // an id.
  uint256 public constant VANILLA_TYPE       = 9 << TYPE_BOUNDARY;
  // Disables role check
  uint256 public constant DISABLING_TYPE     = 10 << TYPE_BOUNDARY;

  // Experimental tokens are meant to demonstrate
  // properties of the system. The flag may be used
  // in conjunction with other types.
  uint256 public constant EXPERIMENTAL_TYPE = 2**TYPE_WIDTH << TYPE_BOUNDARY;

  // Bits that can be set, but shouldn't affect matching
  uint256 public constant NO_MATCH_FLAGS = USE_ONCE | INTERNAL_MASK;

  enum Role {
    // The first value is zero and all tokens should
    // have a positive value.
    Reserved00,

    // Superusers have access to the bulk of the
    // functions of the contract.
    Superuser,

    // Minters have the capacity to create instances
    // of existing tokens subject to restrictions on
    // quantity and whether an individual may hold
    // duplicates.
    Minter,

    // Casters may cast roles upon other users except
    // for superusers who may only be created by
    // other superusers (or the owner).
    Caster,

    // Transferers have the ability to move tokens
    // between accounts.
    Transferer,

    // Configurers can update the URI associated
    // with a token.
    Configurer,

    // Maintainers may update the contract.
    Maintainer,

    // Creators can create new tokens.
    Creator,

    // Limiters can change the maximum number of
    // tokens allowed to be minted.
    Limiter,

    // Burners can destroy minted tokens.
    Burner,

    // Destroyers can remove a created token.
    Destroyer,

    // Oracles provide information about the world.
    // Trusted information like the length of
    // videos submitted for time tokens.
    Oracle,

    // Marker for the end of the list.
    ReservedNeg1
  }

  function roleNameByIndex(Role index)
    public
    pure
    returns (string memory name)
  {
    if(index == Role.Superuser) return "Superuser";
    if(index == Role.Minter) return "Minter";
    if(index == Role.Caster) return "Caster";
    if(index == Role.Transferer) return "Transferer";
    if(index == Role.Configurer) return "Configurer";
    if(index == Role.Maintainer) return "Maintainer";
    if(index == Role.Creator) return "Creator";
    if(index == Role.Limiter) return "Limiter";
    if(index == Role.Burner) return "Burner";
    if(index == Role.Destroyer) return "Destroyer";
    if(index == Role.Oracle) return "Oracle";
    if(index == Role.Reserved00) return "Reserved[0]";
    if(index == Role.ReservedNeg1) return "Reserved[-1]";
  }

  function roleValueForName(string memory roleName)
    public
    pure
    returns (Role role)
  {
    bytes32 hash = keccak256(abi.encodePacked(roleName));
    if(hash == keccak256(abi.encodePacked("Superuser"))) {
      return Role.Superuser;
    }
    if(hash == keccak256(abi.encodePacked("Minter"))) {
      return Role.Minter;
    }
    if(hash == keccak256(abi.encodePacked("Caster"))) {
      return Role.Caster;
    }
    if(hash == keccak256(abi.encodePacked("Transferer"))) {
      return Role.Transferer;
    }
    if(hash == keccak256(abi.encodePacked("Configurer"))) {
      return Role.Configurer;
    }
    if(hash == keccak256(abi.encodePacked("Maintainer"))) {
      return Role.Maintainer;
    }
    if(hash == keccak256(abi.encodePacked("Creator"))) {
      return Role.Creator;
    }
    if(hash == keccak256(abi.encodePacked("Limiter"))) {
      return Role.Limiter;
    }
    if(hash == keccak256(abi.encodePacked("Burner"))) {
      return Role.Burner;
    }
    if(hash == keccak256(abi.encodePacked("Destroyer"))) {
      return Role.Destroyer;
    }
    if(hash == keccak256(abi.encodePacked("Oracle"))) {
      return Role.Oracle;
    }
    if(hash == keccak256(abi.encodePacked("Reserved[0]"))) {
      return Role.Reserved00;
    }
    if(hash == keccak256(abi.encodePacked("Reserved[-1]"))) {
      return Role.ReservedNeg1;
    }
    revert(string(abi.encodePacked("Unknown role type: ", roleName)));
  }
}