// SPDX-License-Identifier: Unlicense

// IERC20.sol

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

/* `MgvLib` contains data structures returned by external calls to Mangrove and the interfaces it uses for its own external calls. */

pragma solidity ^0.8.10;
pragma abicoder v2;

interface IERC20 {
  function totalSupply() external view returns (uint);

  function balanceOf(address account) external view returns (uint);

  function transfer(address recipient, uint amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint);

  function approve(address spender, uint amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool);

  function symbol() external view returns (string memory);

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);

  /// for wETH contract
  function deposit() external payable;

  function withdraw(uint) external;

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: Unlicense

// MgvLib.sol

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

/* `MgvLib` contains data structures returned by external calls to Mangrove and the interfaces it uses for its own external calls. */

pragma solidity ^0.8.10;
pragma abicoder v2;

import "./IERC20.sol";
import "./MgvPack.sol" as P;

/* # Structs
The structs defined in `structs.js` have their counterpart as solidity structs that are easy to manipulate for outside contracts / callers of view functions. */

library MgvLib {
  /*
   Some miscellaneous data types useful to `Mangrove` and external contracts */
  //+clear+

  /* `SingleOrder` holds data about an order-offer match in a struct. Used by `marketOrder` and `internalSnipes` (and some of their nested functions) to avoid stack too deep errors. */
  struct SingleOrder {
    address outbound_tkn;
    address inbound_tkn;
    uint offerId;
    P.Offer.t offer;
    /* `wants`/`gives` mutate over execution. Initially the `wants`/`gives` from the taker's pov, then actual `wants`/`gives` adjusted by offer's price and volume. */
    uint wants;
    uint gives;
    /* `offerDetail` is only populated when necessary. */
    P.OfferDetail.t offerDetail;
    P.Global.t global;
    P.Local.t local;
  }

  /* <a id="MgvLib/OrderResult"></a> `OrderResult` holds additional data for the maker and is given to them _after_ they fulfilled an offer. It gives them their own returned data from the previous call, and an `mgvData` specifying whether the Mangrove encountered an error. */

  struct OrderResult {
    /* `makerdata` holds a message that was either returned by the maker or passed as revert message at the end of the trade execution*/
    bytes32 makerData;
    /* `mgvData` is an [internal Mangrove status code](#MgvOfferTaking/statusCodes) code. */
    bytes32 mgvData;
  }
}

/* # Events
The events emitted for use by bots are listed here: */
contract HasMgvEvents {
  /* * Emitted at the creation of the new Mangrove contract on the pair (`inbound_tkn`, `outbound_tkn`)*/
  event NewMgv();

  /* Mangrove adds or removes wei from `maker`'s account */
  /* * Credit event occurs when an offer is removed from the Mangrove or when the `fund` function is called*/
  event Credit(address indexed maker, uint amount);
  /* * Debit event occurs when an offer is posted or when the `withdraw` function is called */
  event Debit(address indexed maker, uint amount);

  /* * Mangrove reconfiguration */
  event SetActive(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    bool value
  );
  event SetFee(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint value
  );
  event SetGasbase(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint offer_gasbase
  );
  event SetGovernance(address value);
  event SetMonitor(address value);
  event SetVault(address value);
  event SetUseOracle(bool value);
  event SetNotify(bool value);
  event SetGasmax(uint value);
  event SetDensity(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint value
  );
  event SetGasprice(uint value);

  /* Market order execution */
  event OrderStart();
  event OrderComplete(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address indexed taker,
    uint takerGot,
    uint takerGave,
    uint penalty,
    uint feePaid
  );

  /* * Offer execution */
  event OfferSuccess(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint id,
    // `maker` is not logged because it can be retrieved from the state using `(outbound_tkn,inbound_tkn,id)`.
    address taker,
    uint takerWants,
    uint takerGives
  );

  /* Log information when a trade execution reverts or returns a non empty bytes32 word */
  event OfferFail(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint id,
    // `maker` is not logged because it can be retrieved from the state using `(outbound_tkn,inbound_tkn,id)`.
    address taker,
    uint takerWants,
    uint takerGives,
    // `mgvData` may only be `"mgv/makerRevert"`, `"mgv/makerTransferFail"` or `"mgv/makerReceiveFail"`
    bytes32 mgvData
  );

  /* Log information when a posthook reverts */
  event PosthookFail(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint offerId,
    bytes32 posthookData
  );

  /* * After `permit` and `approve` */
  event Approval(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address owner,
    address spender,
    uint value
  );

  /* * Mangrove closure */
  event Kill();

  /* * An offer was created or updated.
  A few words about why we include a `prev` field, and why we don't include a
  `next` field: in theory clients should need neither `prev` nor a `next` field.
  They could just 1. Read the order book state at a given block `b`.  2. On
  every event, update a local copy of the orderbook.  But in practice, we do not
  want to force clients to keep a copy of the *entire* orderbook. There may be a
  long tail of spam. Now if they only start with the first $N$ offers and
  receive a new offer that goes to the end of the book, they cannot tell if
  there are missing offers between the new offer and the end of the local copy
  of the book.
  
  So we add a prev pointer so clients with only a prefix of the book can receive
  out-of-prefix offers and know what to do with them. The `next` pointer is an
  optimization useful in Solidity (we traverse fewer memory locations) but
  useless in client code.
  */
  event OfferWrite(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address maker,
    uint wants,
    uint gives,
    uint gasprice,
    uint gasreq,
    uint id,
    uint prev
  );

  /* * `offerId` was present and is now removed from the book. */
  event OfferRetract(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint id
  );
}

/* # IMaker interface */
interface IMaker {
  /* Called upon offer execution. 
  - If the call fails, Mangrove will not try to transfer funds.
  - If the call succeeds but returndata's first 32 bytes are not 0, Mangrove will not try to transfer funds either.
  - If the call succeeds and returndata's first 32 bytes are 0, Mangrove will try to transfer funds.
  In other words, you may declare failure by reverting or by returning nonzero data. In both cases, those 32 first bytes will be passed back to you during the call to `makerPosthook` in the `result.mgvData` field.
     ```
     function tradeRevert(bytes32 data) internal pure {
       bytes memory revData = new bytes(32);
         assembly {
           mstore(add(revData, 32), data)
           revert(add(revData, 32), 32)
         }
     }
     ```
     */
  function makerExecute(MgvLib.SingleOrder calldata order)
    external
    returns (bytes32);

  /* Called after all offers of an order have been executed. Posthook of the last executed order is called first and full reentrancy into the Mangrove is enabled at this time. `order` recalls key arguments of the order that was processed and `result` recalls important information for updating the current offer. (see [above](#MgvLib/OrderResult))*/
  function makerPosthook(
    MgvLib.SingleOrder calldata order,
    MgvLib.OrderResult calldata result
  ) external;
}

/* # ITaker interface */
interface ITaker {
  /* Inverted mangrove only: call to taker after loans went through */
  function takerTrade(
    address outbound_tkn,
    address inbound_tkn,
    // total amount of outbound_tkn token that was flashloaned to the taker
    uint totalGot,
    // total amount of inbound_tkn token that should be made available
    uint totalGives
  ) external;
}

/* # Monitor interface
If enabled, the monitor receives notification after each offer execution and is read for each pair's `gasprice` and `density`. */
interface IMgvMonitor {
  function notifySuccess(MgvLib.SingleOrder calldata sor, address taker)
    external;

  function notifyFail(MgvLib.SingleOrder calldata sor, address taker) external;

  function read(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (uint gasprice, uint density);
}

pragma solidity ^0.8.10;

// SPDX-License-Identifier: Unlicense

// MgvPack.sol

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

/* ************************************************** *
            GENERATED FILE. DO NOT EDIT.
 * ************************************************** */

/* since you can't convert bool to uint in an expression without conditionals,
 * we add a file-level function and rely on compiler optimization
 */
function uint_of_bool(bool b) pure returns (uint u) {
  assembly {
    u := b
  }
}

// fields are of the form [name,bits,type]

// Can't put all structs under a 'Structs' library due to bad variable shadowing rules in Solidity
// (would generate lots of spurious warnings about a nameclash between Structs.Offer and library Offer for instance)
// struct_defs are of the form [name,obj]
struct OfferStruct {
  uint prev;
  uint next;
  uint wants;
  uint gives;
}
struct OfferDetailStruct {
  address maker;
  uint gasreq;
  uint offer_gasbase;
  uint gasprice;
}
struct GlobalStruct {
  address monitor;
  bool useOracle;
  bool notify;
  uint gasprice;
  uint gasmax;
  bool dead;
}
struct LocalStruct {
  bool active;
  uint fee;
  uint density;
  uint offer_gasbase;
  bool lock;
  uint best;
  uint last;
}

library Offer {
  //some type safety for each struct
  type t is uint;

  uint constant prev_bits = 32;
  uint constant next_bits = 32;
  uint constant wants_bits = 96;
  uint constant gives_bits = 96;

  uint constant prev_before = 0;
  uint constant next_before = prev_before + prev_bits;
  uint constant wants_before = next_before + next_bits;
  uint constant gives_before = wants_before + wants_bits;

  uint constant prev_mask =
    0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  uint constant next_mask =
    0xffffffff00000000ffffffffffffffffffffffffffffffffffffffffffffffff;
  uint constant wants_mask =
    0xffffffffffffffff000000000000000000000000ffffffffffffffffffffffff;
  uint constant gives_mask =
    0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000;

  function to_struct(t __packed)
    internal
    pure
    returns (OfferStruct memory __s)
  {
    unchecked {
      __s.prev = (t.unwrap(__packed) << prev_before) >> (256 - prev_bits);
      __s.next = (t.unwrap(__packed) << next_before) >> (256 - next_bits);
      __s.wants = (t.unwrap(__packed) << wants_before) >> (256 - wants_bits);
      __s.gives = (t.unwrap(__packed) << gives_before) >> (256 - gives_bits);
    }
  }

  function t_of_struct(OfferStruct memory __s) internal pure returns (t) {
    unchecked {
      return pack(__s.prev, __s.next, __s.wants, __s.gives);
    }
  }

  function eq(t __packed1, t __packed2) internal pure returns (bool) {
    unchecked {
      return t.unwrap(__packed1) == t.unwrap(__packed2);
    }
  }

  function pack(
    uint __prev,
    uint __next,
    uint __wants,
    uint __gives
  ) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          ((((0 | ((__prev << (256 - prev_bits)) >> prev_before)) |
            ((__next << (256 - next_bits)) >> next_before)) |
            ((__wants << (256 - wants_bits)) >> wants_before)) |
            ((__gives << (256 - gives_bits)) >> gives_before))
        );
    }
  }

  function unpack(t __packed)
    internal
    pure
    returns (
      uint __prev,
      uint __next,
      uint __wants,
      uint __gives
    )
  {
    unchecked {
      __prev = (t.unwrap(__packed) << prev_before) >> (256 - prev_bits);
      __next = (t.unwrap(__packed) << next_before) >> (256 - next_bits);
      __wants = (t.unwrap(__packed) << wants_before) >> (256 - wants_bits);
      __gives = (t.unwrap(__packed) << gives_before) >> (256 - gives_bits);
    }
  }

  function prev(t __packed) internal pure returns (uint) {
    unchecked {
      return (t.unwrap(__packed) << prev_before) >> (256 - prev_bits);
    }
  }

  function prev(t __packed, uint val) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          (t.unwrap(__packed) & prev_mask) |
            (((val << (256 - prev_bits)) >> prev_before))
        );
    }
  }

  function next(t __packed) internal pure returns (uint) {
    unchecked {
      return (t.unwrap(__packed) << next_before) >> (256 - next_bits);
    }
  }

  function next(t __packed, uint val) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          (t.unwrap(__packed) & next_mask) |
            (((val << (256 - next_bits)) >> next_before))
        );
    }
  }

  function wants(t __packed) internal pure returns (uint) {
    unchecked {
      return (t.unwrap(__packed) << wants_before) >> (256 - wants_bits);
    }
  }

  function wants(t __packed, uint val) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          (t.unwrap(__packed) & wants_mask) |
            (((val << (256 - wants_bits)) >> wants_before))
        );
    }
  }

  function gives(t __packed) internal pure returns (uint) {
    unchecked {
      return (t.unwrap(__packed) << gives_before) >> (256 - gives_bits);
    }
  }

  function gives(t __packed, uint val) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          (t.unwrap(__packed) & gives_mask) |
            (((val << (256 - gives_bits)) >> gives_before))
        );
    }
  }
}

library OfferDetail {
  //some type safety for each struct
  type t is uint;

  uint constant maker_bits = 160;
  uint constant gasreq_bits = 24;
  uint constant offer_gasbase_bits = 24;
  uint constant gasprice_bits = 16;

  uint constant maker_before = 0;
  uint constant gasreq_before = maker_before + maker_bits;
  uint constant offer_gasbase_before = gasreq_before + gasreq_bits;
  uint constant gasprice_before = offer_gasbase_before + offer_gasbase_bits;

  uint constant maker_mask =
    0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;
  uint constant gasreq_mask =
    0xffffffffffffffffffffffffffffffffffffffff000000ffffffffffffffffff;
  uint constant offer_gasbase_mask =
    0xffffffffffffffffffffffffffffffffffffffffffffff000000ffffffffffff;
  uint constant gasprice_mask =
    0xffffffffffffffffffffffffffffffffffffffffffffffffffff0000ffffffff;

  function to_struct(t __packed)
    internal
    pure
    returns (OfferDetailStruct memory __s)
  {
    unchecked {
      __s.maker = address(
        uint160((t.unwrap(__packed) << maker_before) >> (256 - maker_bits))
      );
      __s.gasreq = (t.unwrap(__packed) << gasreq_before) >> (256 - gasreq_bits);
      __s.offer_gasbase =
        (t.unwrap(__packed) << offer_gasbase_before) >>
        (256 - offer_gasbase_bits);
      __s.gasprice =
        (t.unwrap(__packed) << gasprice_before) >>
        (256 - gasprice_bits);
    }
  }

  function t_of_struct(OfferDetailStruct memory __s) internal pure returns (t) {
    unchecked {
      return pack(__s.maker, __s.gasreq, __s.offer_gasbase, __s.gasprice);
    }
  }

  function eq(t __packed1, t __packed2) internal pure returns (bool) {
    unchecked {
      return t.unwrap(__packed1) == t.unwrap(__packed2);
    }
  }

  function pack(
    address __maker,
    uint __gasreq,
    uint __offer_gasbase,
    uint __gasprice
  ) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          ((((0 |
            ((uint(uint160(__maker)) << (256 - maker_bits)) >> maker_before)) |
            ((__gasreq << (256 - gasreq_bits)) >> gasreq_before)) |
            ((__offer_gasbase << (256 - offer_gasbase_bits)) >>
              offer_gasbase_before)) |
            ((__gasprice << (256 - gasprice_bits)) >> gasprice_before))
        );
    }
  }

  function unpack(t __packed)
    internal
    pure
    returns (
      address __maker,
      uint __gasreq,
      uint __offer_gasbase,
      uint __gasprice
    )
  {
    unchecked {
      __maker = address(
        uint160((t.unwrap(__packed) << maker_before) >> (256 - maker_bits))
      );
      __gasreq = (t.unwrap(__packed) << gasreq_before) >> (256 - gasreq_bits);
      __offer_gasbase =
        (t.unwrap(__packed) << offer_gasbase_before) >>
        (256 - offer_gasbase_bits);
      __gasprice =
        (t.unwrap(__packed) << gasprice_before) >>
        (256 - gasprice_bits);
    }
  }

  function maker(t __packed) internal pure returns (address) {
    unchecked {
      return
        address(
          uint160((t.unwrap(__packed) << maker_before) >> (256 - maker_bits))
        );
    }
  }

  function maker(t __packed, address val) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          (t.unwrap(__packed) & maker_mask) |
            (((uint(uint160(val)) << (256 - maker_bits)) >> maker_before))
        );
    }
  }

  function gasreq(t __packed) internal pure returns (uint) {
    unchecked {
      return (t.unwrap(__packed) << gasreq_before) >> (256 - gasreq_bits);
    }
  }

  function gasreq(t __packed, uint val) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          (t.unwrap(__packed) & gasreq_mask) |
            (((val << (256 - gasreq_bits)) >> gasreq_before))
        );
    }
  }

  function offer_gasbase(t __packed) internal pure returns (uint) {
    unchecked {
      return
        (t.unwrap(__packed) << offer_gasbase_before) >>
        (256 - offer_gasbase_bits);
    }
  }

  function offer_gasbase(t __packed, uint val) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          (t.unwrap(__packed) & offer_gasbase_mask) |
            (((val << (256 - offer_gasbase_bits)) >> offer_gasbase_before))
        );
    }
  }

  function gasprice(t __packed) internal pure returns (uint) {
    unchecked {
      return (t.unwrap(__packed) << gasprice_before) >> (256 - gasprice_bits);
    }
  }

  function gasprice(t __packed, uint val) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          (t.unwrap(__packed) & gasprice_mask) |
            (((val << (256 - gasprice_bits)) >> gasprice_before))
        );
    }
  }
}

library Global {
  //some type safety for each struct
  type t is uint;

  uint constant monitor_bits = 160;
  uint constant useOracle_bits = 8;
  uint constant notify_bits = 8;
  uint constant gasprice_bits = 16;
  uint constant gasmax_bits = 24;
  uint constant dead_bits = 8;

  uint constant monitor_before = 0;
  uint constant useOracle_before = monitor_before + monitor_bits;
  uint constant notify_before = useOracle_before + useOracle_bits;
  uint constant gasprice_before = notify_before + notify_bits;
  uint constant gasmax_before = gasprice_before + gasprice_bits;
  uint constant dead_before = gasmax_before + gasmax_bits;

  uint constant monitor_mask =
    0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;
  uint constant useOracle_mask =
    0xffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffff;
  uint constant notify_mask =
    0xffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffff;
  uint constant gasprice_mask =
    0xffffffffffffffffffffffffffffffffffffffffffff0000ffffffffffffffff;
  uint constant gasmax_mask =
    0xffffffffffffffffffffffffffffffffffffffffffffffff000000ffffffffff;
  uint constant dead_mask =
    0xffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffff;

  function to_struct(t __packed)
    internal
    pure
    returns (GlobalStruct memory __s)
  {
    unchecked {
      __s.monitor = address(
        uint160((t.unwrap(__packed) << monitor_before) >> (256 - monitor_bits))
      );
      __s.useOracle = (((t.unwrap(__packed) << useOracle_before) >>
        (256 - useOracle_bits)) > 0);
      __s.notify = (((t.unwrap(__packed) << notify_before) >>
        (256 - notify_bits)) > 0);
      __s.gasprice =
        (t.unwrap(__packed) << gasprice_before) >>
        (256 - gasprice_bits);
      __s.gasmax = (t.unwrap(__packed) << gasmax_before) >> (256 - gasmax_bits);
      __s.dead = (((t.unwrap(__packed) << dead_before) >> (256 - dead_bits)) >
        0);
    }
  }

  function t_of_struct(GlobalStruct memory __s) internal pure returns (t) {
    unchecked {
      return
        pack(
          __s.monitor,
          __s.useOracle,
          __s.notify,
          __s.gasprice,
          __s.gasmax,
          __s.dead
        );
    }
  }

  function eq(t __packed1, t __packed2) internal pure returns (bool) {
    unchecked {
      return t.unwrap(__packed1) == t.unwrap(__packed2);
    }
  }

  function pack(
    address __monitor,
    bool __useOracle,
    bool __notify,
    uint __gasprice,
    uint __gasmax,
    bool __dead
  ) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          ((((((0 |
            ((uint(uint160(__monitor)) << (256 - monitor_bits)) >>
              monitor_before)) |
            ((uint_of_bool(__useOracle) << (256 - useOracle_bits)) >>
              useOracle_before)) |
            ((uint_of_bool(__notify) << (256 - notify_bits)) >>
              notify_before)) |
            ((__gasprice << (256 - gasprice_bits)) >> gasprice_before)) |
            ((__gasmax << (256 - gasmax_bits)) >> gasmax_before)) |
            ((uint_of_bool(__dead) << (256 - dead_bits)) >> dead_before))
        );
    }
  }

  function unpack(t __packed)
    internal
    pure
    returns (
      address __monitor,
      bool __useOracle,
      bool __notify,
      uint __gasprice,
      uint __gasmax,
      bool __dead
    )
  {
    unchecked {
      __monitor = address(
        uint160((t.unwrap(__packed) << monitor_before) >> (256 - monitor_bits))
      );
      __useOracle = (((t.unwrap(__packed) << useOracle_before) >>
        (256 - useOracle_bits)) > 0);
      __notify = (((t.unwrap(__packed) << notify_before) >>
        (256 - notify_bits)) > 0);
      __gasprice =
        (t.unwrap(__packed) << gasprice_before) >>
        (256 - gasprice_bits);
      __gasmax = (t.unwrap(__packed) << gasmax_before) >> (256 - gasmax_bits);
      __dead = (((t.unwrap(__packed) << dead_before) >> (256 - dead_bits)) > 0);
    }
  }

  function monitor(t __packed) internal pure returns (address) {
    unchecked {
      return
        address(
          uint160(
            (t.unwrap(__packed) << monitor_before) >> (256 - monitor_bits)
          )
        );
    }
  }

  function monitor(t __packed, address val) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          (t.unwrap(__packed) & monitor_mask) |
            (((uint(uint160(val)) << (256 - monitor_bits)) >> monitor_before))
        );
    }
  }

  function useOracle(t __packed) internal pure returns (bool) {
    unchecked {
      return (((t.unwrap(__packed) << useOracle_before) >>
        (256 - useOracle_bits)) > 0);
    }
  }

  function useOracle(t __packed, bool val) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          (t.unwrap(__packed) & useOracle_mask) |
            (
              ((uint_of_bool(val) << (256 - useOracle_bits)) >>
                useOracle_before)
            )
        );
    }
  }

  function notify(t __packed) internal pure returns (bool) {
    unchecked {
      return (((t.unwrap(__packed) << notify_before) >> (256 - notify_bits)) >
        0);
    }
  }

  function notify(t __packed, bool val) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          (t.unwrap(__packed) & notify_mask) |
            (((uint_of_bool(val) << (256 - notify_bits)) >> notify_before))
        );
    }
  }

  function gasprice(t __packed) internal pure returns (uint) {
    unchecked {
      return (t.unwrap(__packed) << gasprice_before) >> (256 - gasprice_bits);
    }
  }

  function gasprice(t __packed, uint val) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          (t.unwrap(__packed) & gasprice_mask) |
            (((val << (256 - gasprice_bits)) >> gasprice_before))
        );
    }
  }

  function gasmax(t __packed) internal pure returns (uint) {
    unchecked {
      return (t.unwrap(__packed) << gasmax_before) >> (256 - gasmax_bits);
    }
  }

  function gasmax(t __packed, uint val) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          (t.unwrap(__packed) & gasmax_mask) |
            (((val << (256 - gasmax_bits)) >> gasmax_before))
        );
    }
  }

  function dead(t __packed) internal pure returns (bool) {
    unchecked {
      return (((t.unwrap(__packed) << dead_before) >> (256 - dead_bits)) > 0);
    }
  }

  function dead(t __packed, bool val) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          (t.unwrap(__packed) & dead_mask) |
            (((uint_of_bool(val) << (256 - dead_bits)) >> dead_before))
        );
    }
  }
}

library Local {
  //some type safety for each struct
  type t is uint;

  uint constant active_bits = 8;
  uint constant fee_bits = 16;
  uint constant density_bits = 112;
  uint constant offer_gasbase_bits = 24;
  uint constant lock_bits = 8;
  uint constant best_bits = 32;
  uint constant last_bits = 32;

  uint constant active_before = 0;
  uint constant fee_before = active_before + active_bits;
  uint constant density_before = fee_before + fee_bits;
  uint constant offer_gasbase_before = density_before + density_bits;
  uint constant lock_before = offer_gasbase_before + offer_gasbase_bits;
  uint constant best_before = lock_before + lock_bits;
  uint constant last_before = best_before + best_bits;

  uint constant active_mask =
    0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  uint constant fee_mask =
    0xff0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  uint constant density_mask =
    0xffffff0000000000000000000000000000ffffffffffffffffffffffffffffff;
  uint constant offer_gasbase_mask =
    0xffffffffffffffffffffffffffffffffff000000ffffffffffffffffffffffff;
  uint constant lock_mask =
    0xffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffff;
  uint constant best_mask =
    0xffffffffffffffffffffffffffffffffffffffffff00000000ffffffffffffff;
  uint constant last_mask =
    0xffffffffffffffffffffffffffffffffffffffffffffffffff00000000ffffff;

  function to_struct(t __packed)
    internal
    pure
    returns (LocalStruct memory __s)
  {
    unchecked {
      __s.active = (((t.unwrap(__packed) << active_before) >>
        (256 - active_bits)) > 0);
      __s.fee = (t.unwrap(__packed) << fee_before) >> (256 - fee_bits);
      __s.density =
        (t.unwrap(__packed) << density_before) >>
        (256 - density_bits);
      __s.offer_gasbase =
        (t.unwrap(__packed) << offer_gasbase_before) >>
        (256 - offer_gasbase_bits);
      __s.lock = (((t.unwrap(__packed) << lock_before) >> (256 - lock_bits)) >
        0);
      __s.best = (t.unwrap(__packed) << best_before) >> (256 - best_bits);
      __s.last = (t.unwrap(__packed) << last_before) >> (256 - last_bits);
    }
  }

  function t_of_struct(LocalStruct memory __s) internal pure returns (t) {
    unchecked {
      return
        pack(
          __s.active,
          __s.fee,
          __s.density,
          __s.offer_gasbase,
          __s.lock,
          __s.best,
          __s.last
        );
    }
  }

  function eq(t __packed1, t __packed2) internal pure returns (bool) {
    unchecked {
      return t.unwrap(__packed1) == t.unwrap(__packed2);
    }
  }

  function pack(
    bool __active,
    uint __fee,
    uint __density,
    uint __offer_gasbase,
    bool __lock,
    uint __best,
    uint __last
  ) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          (((((((0 |
            ((uint_of_bool(__active) << (256 - active_bits)) >>
              active_before)) | ((__fee << (256 - fee_bits)) >> fee_before)) |
            ((__density << (256 - density_bits)) >> density_before)) |
            ((__offer_gasbase << (256 - offer_gasbase_bits)) >>
              offer_gasbase_before)) |
            ((uint_of_bool(__lock) << (256 - lock_bits)) >> lock_before)) |
            ((__best << (256 - best_bits)) >> best_before)) |
            ((__last << (256 - last_bits)) >> last_before))
        );
    }
  }

  function unpack(t __packed)
    internal
    pure
    returns (
      bool __active,
      uint __fee,
      uint __density,
      uint __offer_gasbase,
      bool __lock,
      uint __best,
      uint __last
    )
  {
    unchecked {
      __active = (((t.unwrap(__packed) << active_before) >>
        (256 - active_bits)) > 0);
      __fee = (t.unwrap(__packed) << fee_before) >> (256 - fee_bits);
      __density =
        (t.unwrap(__packed) << density_before) >>
        (256 - density_bits);
      __offer_gasbase =
        (t.unwrap(__packed) << offer_gasbase_before) >>
        (256 - offer_gasbase_bits);
      __lock = (((t.unwrap(__packed) << lock_before) >> (256 - lock_bits)) > 0);
      __best = (t.unwrap(__packed) << best_before) >> (256 - best_bits);
      __last = (t.unwrap(__packed) << last_before) >> (256 - last_bits);
    }
  }

  function active(t __packed) internal pure returns (bool) {
    unchecked {
      return (((t.unwrap(__packed) << active_before) >> (256 - active_bits)) >
        0);
    }
  }

  function active(t __packed, bool val) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          (t.unwrap(__packed) & active_mask) |
            (((uint_of_bool(val) << (256 - active_bits)) >> active_before))
        );
    }
  }

  function fee(t __packed) internal pure returns (uint) {
    unchecked {
      return (t.unwrap(__packed) << fee_before) >> (256 - fee_bits);
    }
  }

  function fee(t __packed, uint val) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          (t.unwrap(__packed) & fee_mask) |
            (((val << (256 - fee_bits)) >> fee_before))
        );
    }
  }

  function density(t __packed) internal pure returns (uint) {
    unchecked {
      return (t.unwrap(__packed) << density_before) >> (256 - density_bits);
    }
  }

  function density(t __packed, uint val) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          (t.unwrap(__packed) & density_mask) |
            (((val << (256 - density_bits)) >> density_before))
        );
    }
  }

  function offer_gasbase(t __packed) internal pure returns (uint) {
    unchecked {
      return
        (t.unwrap(__packed) << offer_gasbase_before) >>
        (256 - offer_gasbase_bits);
    }
  }

  function offer_gasbase(t __packed, uint val) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          (t.unwrap(__packed) & offer_gasbase_mask) |
            (((val << (256 - offer_gasbase_bits)) >> offer_gasbase_before))
        );
    }
  }

  function lock(t __packed) internal pure returns (bool) {
    unchecked {
      return (((t.unwrap(__packed) << lock_before) >> (256 - lock_bits)) > 0);
    }
  }

  function lock(t __packed, bool val) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          (t.unwrap(__packed) & lock_mask) |
            (((uint_of_bool(val) << (256 - lock_bits)) >> lock_before))
        );
    }
  }

  function best(t __packed) internal pure returns (uint) {
    unchecked {
      return (t.unwrap(__packed) << best_before) >> (256 - best_bits);
    }
  }

  function best(t __packed, uint val) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          (t.unwrap(__packed) & best_mask) |
            (((val << (256 - best_bits)) >> best_before))
        );
    }
  }

  function last(t __packed) internal pure returns (uint) {
    unchecked {
      return (t.unwrap(__packed) << last_before) >> (256 - last_bits);
    }
  }

  function last(t __packed, uint val) internal pure returns (t) {
    unchecked {
      return
        t.wrap(
          (t.unwrap(__packed) & last_mask) |
            (((val << (256 - last_bits)) >> last_before))
        );
    }
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// MangroveOffer.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

import "../lib/AccessControlled.sol";
import "../interfaces/IOfferLogic.sol";
import "../interfaces/IMangrove.sol";
import "../interfaces/IEIP20.sol";

// Naming scheme:
// `f() public`: can be used as is in all descendants of `this` contract
// `_f() internal`: descendant of this contract should provide a public wrapper of this function
// `__f__() virtual internal`: descendant of this contract may override this function to specialize the strat

/// MangroveOffer is the basic building block to implement a reactive offer that interfaces with the Mangrove
abstract contract MangroveOffer is AccessControlled, IOfferLogic {
  using P.Offer for P.Offer.t;
  using P.OfferDetail for P.OfferDetail.t;
  using P.Global for P.Global.t;
  using P.Local for P.Local.t;

  bytes32 public immutable RENEGED = "mgvOffer/abort/reneged";
  bytes32 public immutable PUTFAILURE = "mgvOffer/abort/putFailed";
  bytes32 public immutable OUTOFLIQUIDITY = "mgvOffer/abort/getFailed";

  // The deployed Mangrove contract
  IMangrove public immutable MGV;

  // `this` contract entypoint is `makerExecute` or `makerPosthook` if `msg.sender == address(MGV)`
  // `this` contract was called on an admin function iff `msg.sender = admin`
  modifier mgvOrAdmin() {
    require(
      msg.sender == admin || msg.sender == address(MGV),
      "AccessControlled/Invalid"
    );
    _;
  }
  // default values
  uint public override OFR_GASREQ = 100_000;

  // necessary function to withdraw funds from Mangrove
  receive() external payable virtual {}

  constructor(address payable _mgv, address admin) AccessControlled(admin) {
    MGV = IMangrove(_mgv);
  }

  /////// Mandatory callback functions

  // `makerExecute` is the callback function to execute all offers that were posted on Mangrove by `this` contract.
  // it may not be overriden although it can be customized using `__lastLook__`, `__put__` and `__get__` hooks.
  // NB #1: When overriding the above hooks, the Offer Makers should make sure they do not revert in order if they wish to post logs in case of bad executions.
  // NB #2: if `makerExecute` does revert, the offer will be considered to be refusing the trade.
  // NB #3: `makerExecute` must return the empty bytes to signal to MGV it wishes to perform the trade. Any other returned byes will signal to MGV that `this` contract does not wish to proceed with the trade
  // NB #4: Reneging on trade by either reverting or returning non empty bytes will have the following effects:
  // * Offer is removed from the Order Book
  // * Offer bounty will be withdrawn from offer provision and sent to the offer taker. The remaining provision will be credited to the maker account on Mangrove
  function makerExecute(ML.SingleOrder calldata order)
    external
    override
    onlyCaller(address(MGV))
    returns (bytes32 ret)
  {
    if (!__lastLook__(order)) {
      // hook to check order details and decide whether `this` contract should renege on the offer.
      revert("mgvOffer/abort/reneged");
    }
    if (__put__(order.gives, order) > 0) {
      revert("mgvOffer/abort/putFailed");
    }
    if (__get__(order.wants, order) > 0) {
      revert("mgvOffer/abort/getFailed");
    }
    return ret;
  }

  // `makerPosthook` is the callback function that is called by Mangrove *after* the offer execution.
  // It may not be overriden although it can be customized via the post-hooks `__posthookSuccess__`, `__posthookGetFailure__`, `__posthookReneged__` and `__posthookFallback__` (see below).
  // Offer Maker SHOULD make sure the overriden posthooks do not revert in order to be able to post logs in case of bad executions.
  function makerPosthook(
    ML.SingleOrder calldata order,
    ML.OrderResult calldata result
  ) external override onlyCaller(address(MGV)) {
    if (result.mgvData == "mgv/tradeSuccess") {
      // toplevel posthook may ignore returned value which is only usefull for compositionality
      __posthookSuccess__(order);
    } else {
      emit LogIncident(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        result.makerData
      );
      __posthookFallback__(order, result);
    }
  }

  // sets default gasreq for `new/updateOffer`
  function setGasreq(uint gasreq) public override mgvOrAdmin {
    require(uint24(gasreq) == gasreq, "mgvOffer/gasreq/overflow");
    OFR_GASREQ = gasreq;
  }

  /// `this` contract needs to approve Mangrove to let it perform outbound token transfer at the end of the `makerExecute` function
  /// NB if anyone can call this function someone could reset it to 0 for griefing
  function approveMangrove(address outbound_tkn, uint amount)
    public
    mgvOrAdmin
  {
    require(
      IEIP20(outbound_tkn).approve(address(MGV), amount),
      "mgvOffer/approve/Fail"
    );
  }

  /// withdraws ETH from the bounty vault of the Mangrove.
  function _withdrawFromMangrove(address payable receiver, uint amount)
    internal
    returns (bool noRevert)
  {
    require(MGV.withdraw(amount), "mgvOffer/withdraw/transferFail");
    if (receiver != address(this)) {
      (noRevert, ) = receiver.call{value: amount}("");
    } else {
      noRevert = true;
    }
  }

  // returns missing provision to repost `offerId` at given `gasreq` and `gasprice`
  // if `offerId` is not in the Order Book, will simply return how much is needed to post
  function _getMissingProvision(
    uint balance, // offer owner balance on Mangrove
    address outbound_tkn,
    address inbound_tkn,
    uint gasreq, // give > type(uint24).max to use `this.OFR_GASREQ()`
    uint gasprice, // give 0 to use Mangrove's gasprice
    uint offerId // set this to 0 if one is not reposting an offer
  ) internal view returns (uint) {
    (P.Global.t globalData, P.Local.t localData) = MGV.config(
      outbound_tkn,
      inbound_tkn
    );
    P.OfferDetail.t offerDetailData = MGV.offerDetails(
      outbound_tkn,
      inbound_tkn,
      offerId
    );
    uint _gp;
    if (globalData.gasprice() > gasprice) {
      _gp = globalData.gasprice();
    } else {
      _gp = gasprice;
    }
    if (gasreq > type(uint24).max) {
      gasreq = OFR_GASREQ;
    }
    uint bounty = (gasreq + localData.offer_gasbase()) * _gp * 10**9; // in WEI
    // if `offerId` is not in the OfferList, all returned values will be 0
    uint currentProvisionLocked = (offerDetailData.gasreq() +
      offerDetailData.offer_gasbase()) *
      offerDetailData.gasprice() *
      10**9;
    uint currentProvision = currentProvisionLocked + balance;
    return (currentProvision >= bounty ? 0 : bounty - currentProvision);
  }

  ////// Default Customizable hooks for Taker Order'execution

  // Define this hook to describe where the inbound token, which are brought by the Offer Taker, should go during Taker Order's execution.
  // Usage of this hook is the following:
  // * `amount` is the amount of `inbound` tokens whose deposit location is to be defined when entering this function
  // * `order` is a recall of the taker order that is at the origin of the current trade.
  // * Function must return `missingPut` (<=`amount`), which is the amount of `inbound` tokens whose deposit location has not been decided (possibly because of a failure) during this function execution
  // NB in case of preceding executions of descendant specific `__put__` implementations, `amount` might be lower than `order.gives` (how much `inbound` tokens the taker gave)
  function __put__(uint amount, ML.SingleOrder calldata order)
    internal
    virtual
    returns (uint missingPut);

  // Define this hook to implement fetching `amount` of outbound tokens, possibly from another source than `this` contract during Taker Order's execution.
  // Usage of this hook is the following:
  // * `amount` is the amount of `outbound` tokens that still needs to be brought to the balance of `this` contract when entering this function
  // * `order` is a recall of the taker order that is at the origin of the current trade.
  // * Function must return `missingGet` (<=`amount`), which is the amount of `outbound` tokens still need to be fetched at the end of this function
  // NB in case of preceding executions of descendant specific `__get__` implementations, `amount` might be lower than `order.wants` (how much `outbound` tokens the taker wants)
  function __get__(uint amount, ML.SingleOrder calldata order)
    internal
    virtual
    returns (uint missingGet);

  // Override this hook to implement a last look check during Taker Order's execution.
  // Return value should be `true` if Taker Order is acceptable.
  // Returning `false` will cause `MakerExecute` to return the "RENEGED" bytes, which are interpreted by MGV as a signal that `this` contract wishes to cancel the trade
  function __lastLook__(ML.SingleOrder calldata order)
    internal
    virtual
    returns (bool proceed)
  {
    order; //shh
    proceed = true;
  }

  ////// Customizable post-hooks.

  // Override this post-hook to implement what `this` contract should do when called back after a successfully executed order.
  function __posthookSuccess__(ML.SingleOrder calldata order)
    internal
    virtual
    returns (bool success)
  {
    order; // shh
    success = true;
  }

  // Override this post-hook to implement fallback behavior when Taker Order's execution failed unexpectedly. Information from Mangrove is accessible in `result.mgvData` for logging purpose.
  function __posthookFallback__(
    ML.SingleOrder calldata order,
    ML.OrderResult calldata result
  ) internal virtual returns (bool success) {
    order;
    result;
    return true;
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// MangroveOffer.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "../MangroveOffer.sol";
import "../../../periphery/MgvReader.sol";
import "../../interfaces/IOfferLogicMulti.sol";

abstract contract MultiUser is IOfferLogicMulti, MangroveOffer {
  mapping(address => mapping(address => mapping(uint => address)))
    internal _offerOwners; // outbound_tkn => inbound_tkn => offerId => ownerAddress

  mapping(address => uint) public mgvBalance; // owner => WEI balance on mangrove
  mapping(address => mapping(address => uint)) public tokenBalanceOf; // erc20 => owner => balance on `this`

  function tokenBalance(address token, address owner) external view override returns (uint) {
    return tokenBalanceOf[token][owner];
  }

  function balanceOnMangrove(address owner) external view override returns (uint) {
    return mgvBalance[owner];
  }

  function offerOwners(
    address reader,
    address outbound_tkn,
    address inbound_tkn,
    uint fromId,
    uint maxOffers
  )
    public
    view
    override
    returns (
      uint nextId,
      uint[] memory offerIds,
      address[] memory __offerOwners
    )
  {
    (
      nextId,
      offerIds, /*offers*/ /*offerDetails*/
      ,

    ) = MgvReader(reader).offerList(
      outbound_tkn,
      inbound_tkn,
      fromId,
      maxOffers
    );
    __offerOwners = new address[](offerIds.length);
    for (uint i = 0; i < offerIds.length; i++) {
      __offerOwners[i] = ownerOf(outbound_tkn, inbound_tkn, offerIds[i]);
    }
  }

  function creditOnMgv(address owner, uint balance) internal {
    mgvBalance[owner] += balance;
    emit CreditMgvUser(owner, balance);
  }

  function debitOnMgv(address owner, uint amount) internal {
    require(mgvBalance[owner] >= amount, "Multi/debitOnMgv/insufficient");
    mgvBalance[owner] -= amount;
    emit DebitMgvUser(owner, amount);
  }

  function creditToken(
    address token,
    address owner,
    uint amount
  ) internal {
    tokenBalanceOf[token][owner] += amount;
    emit CreditUserTokenBalance(owner, token, amount);
  }

  function debitToken(
    address token,
    address owner,
    uint amount
  ) internal {
    if (amount == 0) {
      return;
    }
    require(
      tokenBalanceOf[token][owner] >= amount,
      "Multi/debitToken/insufficient"
    );
    tokenBalanceOf[token][owner] -= amount;
    emit DebitUserTokenBalance(owner, token, amount);
  }

  function redeemToken(
    address token,
    address receiver,
    uint amount
  ) external override returns (bool success) {
    require(msg.sender != address(this), "Mutli/noReentrancy");
    debitToken(token, msg.sender, amount);
    success = IEIP20(token).transfer(receiver, amount);
  }

  function depositToken(address token, uint amount)
    external
    override
    returns (
      //override
      bool success
    )
  {
    uint balBefore = IEIP20(token).balanceOf(address(this));
    success = IEIP20(token).transferFrom(msg.sender, address(this), amount);
    require(
      IEIP20(token).balanceOf(address(this)) - balBefore == amount,
      "Multi/transferFail"
    );
    creditToken(token, msg.sender, amount);
  }

  function addOwner(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId,
    address owner
  ) internal {
    _offerOwners[outbound_tkn][inbound_tkn][offerId] = owner;
    emit NewOwnedOffer(outbound_tkn, inbound_tkn, offerId, owner);
  }

  function ownerOf(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId
  ) public view override returns (address owner) {
    owner = _offerOwners[outbound_tkn][inbound_tkn][offerId];
    require(owner != address(0), "multiUser/unkownOffer");
  }

  /// withdraws ETH from the bounty vault of the Mangrove.
  /// NB: `Mangrove.fund` function need not be called by `this` so is not included here.
  /// Warning: this function should not be called internally for msg.sender provision is being checked
  function withdrawFromMangrove(address payable receiver, uint amount)
    external
    override
    returns (bool noRevert)
  {
    require(msg.sender != address(this), "Mutli/noReentrancy");
    debitOnMgv(msg.sender, amount);
    return _withdrawFromMangrove(receiver, amount);
  }

  function fundMangrove() external payable override // override
  {
    require(msg.sender != address(this), "Mutli/noReentrancy");
    fundMangroveInternal(msg.sender, msg.value);
  }

  function fundMangroveInternal(address caller, uint provision) internal {
    // increasing the provision of `this` contract
    MGV.fund{value: provision}();
    // increasing the virtual provision of owner
    creditOnMgv(caller, provision);
  }

  function updateUserBalanceOnMgv(address user, uint mgvBalanceBefore)
    internal
  {
    uint mgvBalanceAfter = MGV.balanceOf(address(this));
    if (mgvBalanceAfter == mgvBalanceBefore) {
      return;
    }
    if (mgvBalanceAfter > mgvBalanceBefore) {
      creditOnMgv(user, mgvBalanceAfter - mgvBalanceBefore);
    } else {
      debitOnMgv(user, mgvBalanceBefore - mgvBalanceAfter);
    }
  }

  function newOffer(
    address outbound_tkn, // address of the ERC20 contract managing outbound tokens
    address inbound_tkn, // address of the ERC20 contract managing outbound tokens
    uint wants, // amount of `inbound_tkn` required for full delivery
    uint gives, // max amount of `outbound_tkn` promised by the offer
    uint gasreq, // max gas required by the offer when called. If maxUint256 is used here, default `OFR_GASREQ` will be considered instead
    uint gasprice, // gasprice that should be consider to compute the bounty (Mangrove's gasprice will be used if this value is lower)
    uint pivotId // identifier of an offer in the (`outbound_tkn,inbound_tkn`) Offer List after which the new offer should be inserted (gas cost of insertion will increase if the `pivotId` is far from the actual position of the new offer)
  ) external payable override returns (uint offerId) {
    require(msg.sender != address(this), "Mutli/noReentrancy");
    offerId = newOfferInternal(
      outbound_tkn,
      inbound_tkn,
      wants,
      gives,
      gasreq,
      gasprice,
      pivotId,
      msg.sender,
      msg.value
    );
  }

  // Calls new offer on Mangrove. If successful the function will:
  // 1. Update `_offerOwners` mapping `caller` to returned `offerId`
  // 2. maintain `mgvBalance` with the redeemable WEIs for caller on Mangrove
  // This call will revert if `newOffer` reverts on Mangrove or if `caller` does not have the provisions to cover for the bounty.
  function newOfferInternal(
    address outbound_tkn, // address of the ERC20 contract managing outbound tokens
    address inbound_tkn, // address of the ERC20 contract managing outbound tokens
    uint wants, // amount of `inbound_tkn` required for full delivery
    uint gives, // max amount of `outbound_tkn` promised by the offer
    uint gasreq, // max gas required by the offer when called. If maxUint256 is used here, default `OFR_GASREQ` will be considered instead
    uint gasprice, // gasprice that should be consider to compute the bounty (Mangrove's gasprice will be used if this value is lower)
    uint pivotId,
    address caller,
    uint provision
  ) internal returns (uint offerId) {
    uint weiBalanceBefore = MGV.balanceOf(address(this));
    if (gasreq > type(uint24).max) {
      gasreq = OFR_GASREQ;
    }
    // this call could revert if this contract does not have the provision to cover the bounty
    offerId = MGV.newOffer{value: provision}(
      outbound_tkn,
      inbound_tkn,
      wants,
      gives,
      gasreq,
      gasprice,
      pivotId
    );
    //setting owner of offerId
    addOwner(outbound_tkn, inbound_tkn, offerId, caller);
    //updating wei balance of owner will revert if msg.sender does not have the funds
    updateUserBalanceOnMgv(caller, weiBalanceBefore);
  }

  function updateOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId,
    uint offerId
  ) external payable override {
    (uint offerId_, string memory reason) = updateOfferInternal(
      outbound_tkn,
      inbound_tkn,
      wants,
      gives,
      gasreq,
      gasprice,
      pivotId,
      offerId,
      msg.sender,
      msg.value
    );
    require(offerId_ > 0, reason);
  }

  // Calls update offer on Mangrove. If successful the function will take care of maintaining `mgvBalance` for offer owner.
  // This call does not revert if `updateOffer` fails on Mangrove, due for instance to low density or incorrect `wants`/`gives`.
  // It will however revert if user does not have the provision to cover the bounty (in case of gas increase).
  // When offer failed to be updated, the returned value is always 0 and the revert message. Otherwise it is equal to `offerId` and the empty string.
  function updateOfferInternal(
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId,
    uint offerId,
    address caller,
    uint provision // dangerous to use msg.value in a internal call
  ) internal returns (uint, string memory) {
    require(
      caller == ownerOf(outbound_tkn, inbound_tkn, offerId),
      "Multi/updateOffer/unauthorized"
    );
    uint weiBalanceBefore = MGV.balanceOf(address(this));
    if (gasreq > type(uint24).max) {
      gasreq = OFR_GASREQ;
    }
    try
      MGV.updateOffer{value: provision}(
        outbound_tkn,
        inbound_tkn,
        wants,
        gives,
        gasreq,
        gasprice,
        pivotId,
        offerId
      )
    {
      updateUserBalanceOnMgv(caller, weiBalanceBefore);
      return (offerId, "");
    } catch Error(string memory reason) {
      return (0, reason);
    }
  }

  // Retracts `offerId` from the (`outbound_tkn`,`inbound_tkn`) Offer list of Mangrove. Function call will throw if `this` contract is not the owner of `offerId`.
  function retractOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId,
    bool deprovision // if set to `true`, `this` contract will receive the remaining provision (in WEI) associated to `offerId`.
  ) external override returns (uint received) {
    received = retractOfferInternal(
      outbound_tkn,
      inbound_tkn,
      offerId,
      deprovision,
      msg.sender
    );
  }

  function retractOfferInternal(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId,
    bool deprovision,
    address caller
  ) internal returns (uint received) {
    require(
      _offerOwners[outbound_tkn][inbound_tkn][offerId] == caller,
      "Multi/retractOffer/unauthorized"
    );
    received = MGV.retractOffer(
      outbound_tkn,
      inbound_tkn,
      offerId,
      deprovision
    );
    if (received > 0) {
      creditOnMgv(caller, received);
    }
  }

  function getMissingProvision(
    address outbound_tkn,
    address inbound_tkn,
    uint gasreq,
    uint gasprice,
    uint offerId
  ) public view override returns (uint) {
    uint balance;
    if (offerId != 0) {
      address owner = ownerOf(outbound_tkn, inbound_tkn, offerId);
      balance = mgvBalance[owner];
    }
    return
      _getMissingProvision(
        balance,
        outbound_tkn,
        inbound_tkn,
        gasreq,
        gasprice,
        offerId
      );
  }

  // put received inbound tokens on offer owner account
  function __put__(uint amount, ML.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    address owner = ownerOf(
      order.outbound_tkn,
      order.inbound_tkn,
      order.offerId
    );
    creditToken(order.inbound_tkn, owner, amount);
    return 0;
  }

  // get outbound tokens from offer owner account
  function __get__(uint amount, ML.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    address owner = ownerOf(
      order.outbound_tkn,
      order.inbound_tkn,
      order.offerId
    );
    uint ownerBalance = tokenBalanceOf[order.outbound_tkn][owner];
    if (ownerBalance < amount) {
      debitToken(order.outbound_tkn, owner, ownerBalance);
      return (amount - ownerBalance);
    } else {
      debitToken(order.outbound_tkn, owner, amount);
      return 0;
    }
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// Persistent.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "./MultiUser.sol";

/// MangroveOffer is the basic building block to implement a reactive offer that interfaces with the Mangrove
abstract contract MultiUserPersistent is MultiUser {
  using P.Offer for P.Offer.t;
  using P.OfferDetail for P.OfferDetail.t;

  function __residualWants__(ML.SingleOrder calldata order)
    internal
    virtual
    returns (uint)
  {
    return order.offer.wants() - order.gives;
  }

  function __residualGives__(ML.SingleOrder calldata order)
    internal
    virtual
    returns (uint)
  {
    return order.offer.gives() - order.wants;
  }

  function __posthookSuccess__(ML.SingleOrder calldata order)
    internal
    virtual
    override
    returns (bool)
  {
    uint new_gives = __residualGives__(order);
    uint new_wants = __residualWants__(order);
    if (new_gives == 0) {
      // gas saving
      return true;
    }
    try
      MGV.updateOffer(
        order.outbound_tkn,
        order.inbound_tkn,
        new_wants,
        new_gives,
        order.offerDetail.gasreq(),
        order.offerDetail.gasprice(),
        order.offer.next(),
        order.offerId
      )
    {
      return true;
    } catch {
      // density could be too low, or offer provision be insufficient
      retractOfferInternal(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        true,
        ownerOf(order.outbound_tkn, order.inbound_tkn, order.offerId)
      );
      return false;
    }
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// Persistent.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

import "../OfferLogics/MultiUsers/Persistent.sol";
import "../interfaces/IOrderLogic.sol";

contract MangroveOrder is MultiUserPersistent, IOrderLogic {
  using P.Local for P.Local.t;

  // `blockToLive[token1][token2][offerId]` gives block number beyond which the offer should renege on trade.
  mapping(address => mapping(address => mapping(uint => uint))) public expiring;

  constructor(address payable _MGV, address admin) MangroveOffer(_MGV, admin) {}

  // transfer with no revert
  function transferERC(
    IEIP20 token,
    address recipient,
    uint amount
  ) internal returns (bool) {
    if (amount == 0) {
      return true;
    }
    (bool success, bytes memory data) = address(token).call(
      abi.encodeWithSelector(token.transfer.selector, recipient, amount)
    );
    return (success && (data.length == 0 || abi.decode(data, (bool))));
  }

  function __lastLook__(ML.SingleOrder calldata order)
    internal
    virtual
    override
    returns (bool)
  {
    uint exp = expiring[order.outbound_tkn][order.inbound_tkn][order.offerId];
    return (exp == 0 || block.number <= exp);
  }

  // revert when order was partially filled and it is not allowed
  function checkCompleteness(
    address outbound_tkn,
    address inbound_tkn,
    TakerOrder calldata tko,
    TakerOrderResult memory res
  ) internal view returns (bool isPartial) {
    // revert if sell is partial and `partialFillNotAllowed` and not posting residual
    if (tko.selling) {
      return res.takerGave >= tko.gives;
    }
    // revert if buy is partial and `partialFillNotAllowed` and not posting residual
    if (!tko.selling) {
      (, P.Local.t local) = MGV.config(outbound_tkn, inbound_tkn);
      return res.takerGot >= tko.wants - (tko.wants * local.fee()) / 10_000;
    }
  }

  // `this` contract MUST have approved Mangrove for inbound token transfer
  // `msg.sender` MUST have approved `this` contract for at least the same amount
  // provision for posting a resting order MAY be sent when calling this function
  // gasLimit of this `tx` MUST be at least `(retryNumber+1)*gasForMarketOrder`
  // msg.value SHOULD contain enough native token to cover for the resting order provision
  // msg.value MUST be 0 if `!restingOrder` otherwise tranfered WEIs are burnt.

  function take(TakerOrder calldata tko)
    external
    payable
    returns (TakerOrderResult memory res)
  {
    (address outbound_tkn, address inbound_tkn) = tko.selling
      ? (tko.quote, tko.base)
      : (tko.base, tko.quote);
    require(
      IEIP20(inbound_tkn).transferFrom(msg.sender, address(this), tko.gives),
      "mgvOrder/mo/transferInFail"
    );
    // passing an iterated market order with the transfered funds
    for (uint i = 0; i < tko.retryNumber + 1; i++) {
      if (tko.gasForMarketOrder != 0 && gasleft() < tko.gasForMarketOrder) {
        break;
      }
      (uint takerGot_, uint takerGave_, uint bounty_) = MGV.marketOrder({
        outbound_tkn: outbound_tkn, // expecting quote (outbound) when selling
        inbound_tkn: inbound_tkn,
        takerWants: tko.wants,
        takerGives: tko.gives,
        fillWants: tko.selling ? false : true // only buy order should try to fill takerWants
      });
      res.takerGot += takerGot_;
      res.takerGave += takerGave_;
      res.bounty += bounty_;
      if (takerGot_ == 0 && bounty_ == 0) {
        break;
      }
    }
    bool isComplete = checkCompleteness(outbound_tkn, inbound_tkn, tko, res);
    // requiring `partialFillNotAllowed` => `isComplete \/ restingOrder`
    require(
      !tko.partialFillNotAllowed || isComplete || tko.restingOrder,
      "mgvOrder/mo/noPartialFill"
    );

    // sending received tokens to taker
    if (res.takerGot > 0) {
      require(
        IEIP20(outbound_tkn).transfer(msg.sender, res.takerGot),
        "mgvOrder/mo/transferOutFail"
      );
    }

    // at this points the following invariants hold:
    // taker received `takerGot` outbound tokens
    // `this` contract inbound token balance is credited of `tko.gives - takerGave`. NB this amount cannot be redeemed by taker yet since `creditToken` was not called
    // `this` contract's WEI balance is credited of `msg.value + bounty`

    if (tko.restingOrder && !isComplete) {
      // resting limit order for the residual of the taker order
      // this call will credit offer owner virtual account on Mangrove with msg.value before trying to post the offer
      // `offerId_==0` if mangrove rejects the update because of low density.
      // If user does not have enough funds, call will revert
      res.offerId = newOfferInternal({
        outbound_tkn: inbound_tkn,
        inbound_tkn: outbound_tkn,
        wants: tko.wants - res.takerGot,
        gives: tko.gives - res.takerGave,
        gasreq: OFR_GASREQ,
        gasprice: 0,
        pivotId: 0, // offer should be best in the book
        caller: msg.sender, // msg.sender is the owner of the resting order
        provision: msg.value
      });

      __logOwnerShipRelation__({
        owner: msg.sender,
        outbound_tkn: inbound_tkn,
        inbound_tkn: outbound_tkn,
        offerId: res.offerId
      });

      emit OrderSummary({
        base: tko.base,
        quote: tko.quote,
        selling: tko.selling,
        taker: msg.sender,
        takerGot: res.takerGot,
        takerGave: res.takerGave,
        penalty: res.bounty,
        restingOrderId: res.offerId
      });

      if (res.offerId == 0) {
        // unable to post resting order
        // reverting because partial fill is not an option
        require(!tko.partialFillNotAllowed, "mgvOrder/mo/noPartialFill");
        // sending partial fill to taker --when partial fill is allowed
        require(
          IEIP20(inbound_tkn).transfer(msg.sender, tko.gives - res.takerGave),
          "mgvOrder/mo/transferInFail"
        );
        // msg.value is no longer needed so sending it back to msg.sender along with possible collected bounty
        if (msg.value + res.bounty > 0) {
          (bool noRevert, ) = msg.sender.call{value: msg.value + res.bounty}(
            ""
          );
          require(noRevert, "mgvOrder/mo/refundProvisionFail");
        }
        return res;
      } else {
        // offer was successfully posted
        // crediting offer owner's balance with amount of offered tokens (transfered from caller at the begining of this function)
        // NB `inb` is the outbound token for the resting order
        creditToken(inbound_tkn, msg.sender, tko.gives - res.takerGave);

        // setting a time to live for the resting order
        if (tko.blocksToLiveForRestingOrder > 0) {
          expiring[inbound_tkn][outbound_tkn][res.offerId] =
            block.number +
            tko.blocksToLiveForRestingOrder;
        }
        return res;
      }
    } else {
      // either fill was complete or taker does not want to post residual as a resting order
      // transfering remaining inbound tokens to msg.sender
      require(
        IEIP20(inbound_tkn).transfer(msg.sender, tko.gives - res.takerGave),
        "mgvOrder/mo/transferInFail"
      );
      // transfering potential bounty and msg.value back to the taker
      if (msg.value + res.bounty > 0) {
        (bool noRevert, ) = msg.sender.call{value: msg.value + res.bounty}("");
        require(noRevert, "mgvOrder/mo/refundFail");
      }
      emit OrderSummary({
        base: tko.base,
        quote: tko.quote,
        selling: tko.selling,
        taker: msg.sender,
        takerGot: res.takerGot,
        takerGave: res.takerGave,
        penalty: res.bounty,
        restingOrderId: 0
      });
      return res;
    }
  }

  // default __get__ method inherited from `MultiUser` is to fetch liquidity from `this` contract
  // we do not want to change this since `creditToken`, during the `take` function that created the resting order, will allow one to fulfill any incoming order
  // However, default __put__ method would deposit tokens in this contract, instead we want forward received liquidity to offer owner

  function __put__(uint amount, ML.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    address owner = ownerOf(
      order.outbound_tkn,
      order.inbound_tkn,
      order.offerId
    );
    // IEIP20(order.inbound_tkn).transfer(owner, amount);
    // return 0;
    return transferERC(IEIP20(order.inbound_tkn), owner, amount) ? 0 : amount;
  }

  // we need to make sure that if offer is taken and not reposted (because of insufficient provision or density) then remaining provision and outbound tokens are sent back to owner

  function redeemAll(ML.SingleOrder calldata order, address owner)
    internal
    returns (bool)
  {
    // Resting order was not reposted, sending out/in tokens to original taker
    // balOut was increased during `take` function and is now possibly empty
    uint balOut = tokenBalanceOf[order.outbound_tkn][owner];
    if (!transferERC(IEIP20(order.outbound_tkn), owner, balOut)) {
      emit LogIncident(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        "mgvOrder/redeemAll/transferOut"
      );
      return false;
    }
    // should not move `debitToken` before the above transfer that does not revert when failing
    // offer owner might still recover tokens later using `redeemToken` external call
    debitToken(order.outbound_tkn, owner, balOut);
    // balIn contains the amount of tokens that was received during the trade that triggered this posthook
    uint balIn = tokenBalanceOf[order.inbound_tkn][owner];
    if (!transferERC(IEIP20(order.inbound_tkn), owner, balIn)) {
      emit LogIncident(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        "mgvOrder/redeemAll/transferIn"
      );
      return false;
    }
    debitToken(order.inbound_tkn, owner, balIn);
    return true;
  }

  function __posthookSuccess__(ML.SingleOrder calldata order)
    internal
    virtual
    override
    returns (bool)
  {
    // trying to repost offer remainder
    if (super.__posthookSuccess__(order)) {
      // if `success` then offer residual was reposted and nothing needs to be done
      // else we need to send the remaining outbounds tokens to owner and their remaining provision on mangrove (offer was deprovisioned in super call)
      return true;
    }
    address owner = ownerOf(
      order.outbound_tkn,
      order.inbound_tkn,
      order.offerId
    );
    // returning all inbound/outbound tokens that belong to the original taker to their balance
    if (!redeemAll(order, owner)) {
      return false;
    }
    // returning remaining WEIs
    // NB because offer was not reposted, it has already been deprovisioned during `super.__posthookSuccess__`
    // NB `_withdrawFromMangrove` performs a call and might be subject to reentrancy.
    debitOnMgv(owner, mgvBalance[owner]);
    // NB cannot revert here otherwise user will not be able to collect automatically in/out tokens (above transfers)
    // if the caller of this contract is not an EOA, funds would be lost.
    if (!_withdrawFromMangrove(payable(owner), mgvBalance[owner])) {
      // this code might be reached if `owner` is not an EOA and has no `receive` or `fallback` payable method.
      // in this case the provision is lost and one should not revert, to the risk of being unable to recover in/out tokens transfered earlier
      emit LogIncident(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        "mgvOrder/posthook/transferWei"
      );
      return false;
    }
    return true;
  }

  // in case of an offer with a blocks-to-live option enabled, resting order might renege on trade
  // in this case, __posthookFallback__ will be called.
  function __posthookFallback__(
    ML.SingleOrder calldata order,
    ML.OrderResult calldata result
  ) internal virtual override returns (bool) {
    result; //shh
    address owner = ownerOf(
      order.outbound_tkn,
      order.inbound_tkn,
      order.offerId
    );
    return redeemAll(order, owner);
  }

  function __logOwnerShipRelation__(
    address owner,
    address outbound_tkn,
    address inbound_tkn,
    uint offerId
  ) internal virtual {
    owner; //ssh
    outbound_tkn; //ssh
    inbound_tkn; //ssh
    offerId; //ssh
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// Persistent.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

import "./MangroveOrder.sol";

contract MangroveOrderEnriched is MangroveOrder {
  // `next[out_tkn][in_tkn][owner][id] = id'` with `next[out_tkn][in_tkn][owner][0]==0` iff owner has now offers on the semi book (out,in)
  mapping(address => mapping(address => mapping(address => mapping(uint => uint)))) next;

  constructor(address payable _MGV, address admin) MangroveOrder(_MGV, admin) {}

  function __logOwnerShipRelation__(
    address owner,
    address outbound_tkn,
    address inbound_tkn,
    uint offerId
  ) internal virtual override {
    uint head = next[outbound_tkn][inbound_tkn][owner][0];
    next[outbound_tkn][inbound_tkn][owner][0] = offerId;
    if (head != 0) {
      next[outbound_tkn][inbound_tkn][owner][offerId] = head;
    }
  }

  // we let the following view function consume loads of gas units in exchange of a rather minimalistic state bookeeping
  function offersOfOwner(
    address owner,
    address outbound_tkn,
    address inbound_tkn
  ) external view returns (uint[] memory live, uint[] memory dead) {
    uint head = next[outbound_tkn][inbound_tkn][owner][0];
    uint id = head;
    uint n_live = 0;
    uint n_dead = 0;
    while (id != 0) {
      if (MGV.isLive(MGV.offers(outbound_tkn, inbound_tkn, id))) {
        n_live++;
      } else {
        n_dead++;
      }
      id = next[outbound_tkn][inbound_tkn][owner][id];
    }
    live = new uint[](n_live);
    dead = new uint[](n_dead);
    id = head;
    n_live = 0;
    n_dead = 0;
    while (id != 0) {
      if (MGV.isLive(MGV.offers(outbound_tkn, inbound_tkn, id))) {
        live[n_live++] = id;
      } else {
        dead[n_dead++] = id;
      }
      id = next[outbound_tkn][inbound_tkn][owner][id];
    }
    return (live, dead);
  }
}

// SPDX-License-Identifier: Unlicense

// IERC20.sol

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

/* `MgvLib` contains data structures returned by external calls to Mangrove and the interfaces it uses for its own external calls. */

pragma solidity ^0.8.10;
pragma abicoder v2;

interface IEIP20 {
  function totalSupply() external view returns (uint);

  function balanceOf(address account) external view returns (uint);

  function transfer(address recipient, uint amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint);

  function approve(address spender, uint amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool);

  function symbol() external view returns (string memory);

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);

  /// for wETH contract
  function deposit() external payable;

  function withdraw(uint) external;

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.2. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;
import {MgvLib as ML, P, IMaker} from "../../MgvLib.sol";

interface IMangrove {
  event Approval(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address owner,
    address spender,
    uint value
  );
  event Credit(address indexed maker, uint amount);
  event Debit(address indexed maker, uint amount);
  event Kill();
  event NewMgv();
  event OfferFail(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint id,
    address taker,
    uint takerWants,
    uint takerGives,
    bytes32 mgvData
  );
  event OfferRetract(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint id
  );
  event OfferSuccess(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint id,
    address taker,
    uint takerWants,
    uint takerGives
  );
  event OfferWrite(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address maker,
    uint wants,
    uint gives,
    uint gasprice,
    uint gasreq,
    uint id,
    uint prev
  );
  event OrderComplete(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address indexed taker,
    uint takerGot,
    uint takerGave,
    uint penalty
  );
  event OrderStart();
  event PosthookFail(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint offerId
  );
  event SetActive(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    bool value
  );
  event SetDensity(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint value
  );
  event SetFee(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint value
  );
  event SetGasbase(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint offer_gasbase
  );
  event SetGasmax(uint value);
  event SetGasprice(uint value);
  event SetGovernance(address value);
  event SetMonitor(address value);
  event SetNotify(bool value);
  event SetUseOracle(bool value);
  event SetVault(address value);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external view returns (bytes32);

  function activate(
    address outbound_tkn,
    address inbound_tkn,
    uint fee,
    uint density,
    uint offer_gasbase
  ) external;

  function allowances(
    address,
    address,
    address,
    address
  ) external view returns (uint);

  function approve(
    address outbound_tkn,
    address inbound_tkn,
    address spender,
    uint value
  ) external returns (bool);

  function balanceOf(address) external view returns (uint);

  function best(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (uint);

  function config(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (P.Global.t, P.Local.t);

  function configInfo(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (P.GlobalStruct memory global, P.LocalStruct memory local);

  function deactivate(address outbound_tkn, address inbound_tkn) external;

  function flashloan(ML.SingleOrder memory sor, address taker)
    external
    returns (uint gasused);

  function fund(address maker) external payable;

  function fund() external payable;

  function governance() external view returns (address);

  function isLive(P.Offer.t offer) external pure returns (bool);

  function kill() external;

  function locked(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (bool);

  function marketOrder(
    address outbound_tkn,
    address inbound_tkn,
    uint takerWants,
    uint takerGives,
    bool fillWants
  )
    external
    returns (
      uint,
      uint,
      uint
    );

  function marketOrderFor(
    address outbound_tkn,
    address inbound_tkn,
    uint takerWants,
    uint takerGives,
    bool fillWants,
    address taker
  )
    external
    returns (
      uint takerGot,
      uint takerGave,
      uint bounty
    );

  function newOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId
  ) external payable returns (uint);

  function nonces(address) external view returns (uint);

  function offerDetails(
    address,
    address,
    uint
  ) external view returns (P.OfferDetail.t);

  function offerInfo(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId
  )
    external
    view
    returns (
      P.OfferStruct memory offer,
      P.OfferDetailStruct memory offerDetail
    );

  function offers(
    address,
    address,
    uint
  ) external view returns (P.Offer.t);

  function permit(
    address outbound_tkn,
    address inbound_tkn,
    address owner,
    address spender,
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function retractOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId,
    bool deprovision
  ) external returns (uint provision);

  function setDensity(
    address outbound_tkn,
    address inbound_tkn,
    uint density
  ) external;

  function setFee(
    address outbound_tkn,
    address inbound_tkn,
    uint fee
  ) external;

  function setGasbase(
    address outbound_tkn,
    address inbound_tkn,
    uint offer_gasbase
  ) external;

  function setGasmax(uint gasmax) external;

  function setGasprice(uint gasprice) external;

  function setGovernance(address governanceAddress) external;

  function setMonitor(address monitor) external;

  function setNotify(bool notify) external;

  function setUseOracle(bool useOracle) external;

  function setVault(address vaultAddress) external;

  function snipes(
    address outbound_tkn,
    address inbound_tkn,
    uint[4][] memory targets,
    bool fillWants
  )
    external
    returns (
      uint,
      uint,
      uint,
      uint
    );

  function snipesFor(
    address outbound_tkn,
    address inbound_tkn,
    uint[4][] memory targets,
    bool fillWants,
    address taker
  )
    external
    returns (
      uint successes,
      uint takerGot,
      uint takerGave,
      uint bounty
    );

  function updateOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId,
    uint offerId
  ) external payable;

  function vault() external view returns (address);

  function withdraw(uint amount) external returns (bool noRevert);

  receive() external payable;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[{"internalType":"address","name":"governance","type":"address"},{"internalType":"uint256","name":"gasprice","type":"uint256"},{"internalType":"uint256","name":"gasmax","type":"uint256"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"maker","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Credit","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"maker","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Debit","type":"event"},{"anonymous":false,"inputs":[],"name":"Kill","type":"event"},{"anonymous":false,"inputs":[],"name":"NewMgv","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"address","name":"taker","type":"address"},{"indexed":false,"internalType":"uint256","name":"takerWants","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"takerGives","type":"uint256"},{"indexed":false,"internalType":"bytes32","name":"mgvData","type":"bytes32"}],"name":"OfferFail","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"uint256","name":"id","type":"uint256"}],"name":"OfferRetract","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"address","name":"taker","type":"address"},{"indexed":false,"internalType":"uint256","name":"takerWants","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"takerGives","type":"uint256"}],"name":"OfferSuccess","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"address","name":"maker","type":"address"},{"indexed":false,"internalType":"uint256","name":"wants","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"gives","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"gasprice","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"gasreq","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"prev","type":"uint256"}],"name":"OfferWrite","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"taker","type":"address"},{"indexed":false,"internalType":"uint256","name":"takerGot","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"takerGave","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"penalty","type":"uint256"}],"name":"OrderComplete","type":"event"},{"anonymous":false,"inputs":[],"name":"OrderStart","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"uint256","name":"offerId","type":"uint256"}],"name":"PosthookFail","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"bool","name":"value","type":"bool"}],"name":"SetActive","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"SetDensity","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"SetFee","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"uint256","name":"offer_gasbase","type":"uint256"}],"name":"SetGasbase","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"SetGasmax","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"SetGasprice","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"value","type":"address"}],"name":"SetGovernance","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"value","type":"address"}],"name":"SetMonitor","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bool","name":"value","type":"bool"}],"name":"SetNotify","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bool","name":"value","type":"bool"}],"name":"SetUseOracle","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"value","type":"address"}],"name":"SetVault","type":"event"},{"inputs":[],"name":"DOMAIN_SEPARATOR","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"PERMIT_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"fee","type":"uint256"},{"internalType":"uint256","name":"density","type":"uint256"},{"internalType":"uint256","name":"offer_gasbase","type":"uint256"}],"name":"activate","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"name":"allowances","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"}],"name":"best","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"}],"name":"config","outputs":[{"internalType":"Global.t","name":"_global","type":"uint256"},{"internalType":"Local.t","name":"_local","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"}],"name":"configInfo","outputs":[{"components":[{"internalType":"address","name":"monitor","type":"address"},{"internalType":"bool","name":"useOracle","type":"bool"},{"internalType":"bool","name":"notify","type":"bool"},{"internalType":"uint256","name":"gasprice","type":"uint256"},{"internalType":"uint256","name":"gasmax","type":"uint256"},{"internalType":"bool","name":"dead","type":"bool"}],"internalType":"struct GlobalStruct","name":"global","type":"tuple"},{"components":[{"internalType":"bool","name":"active","type":"bool"},{"internalType":"uint256","name":"fee","type":"uint256"},{"internalType":"uint256","name":"density","type":"uint256"},{"internalType":"uint256","name":"offer_gasbase","type":"uint256"},{"internalType":"bool","name":"lock","type":"bool"},{"internalType":"uint256","name":"best","type":"uint256"},{"internalType":"uint256","name":"last","type":"uint256"}],"internalType":"struct LocalStruct","name":"local","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"}],"name":"deactivate","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"components":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"offerId","type":"uint256"},{"internalType":"Offer.t","name":"offer","type":"uint256"},{"internalType":"uint256","name":"wants","type":"uint256"},{"internalType":"uint256","name":"gives","type":"uint256"},{"internalType":"OfferDetail.t","name":"offerDetail","type":"uint256"},{"internalType":"Global.t","name":"global","type":"uint256"},{"internalType":"Local.t","name":"local","type":"uint256"}],"internalType":"struct MgvLib.SingleOrder","name":"sor","type":"tuple"},{"internalType":"address","name":"taker","type":"address"}],"name":"flashloan","outputs":[{"internalType":"uint256","name":"gasused","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"maker","type":"address"}],"name":"fund","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"fund","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"governance","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"Offer.t","name":"offer","type":"uint256"}],"name":"isLive","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"kill","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"}],"name":"locked","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"takerWants","type":"uint256"},{"internalType":"uint256","name":"takerGives","type":"uint256"},{"internalType":"bool","name":"fillWants","type":"bool"}],"name":"marketOrder","outputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"takerWants","type":"uint256"},{"internalType":"uint256","name":"takerGives","type":"uint256"},{"internalType":"bool","name":"fillWants","type":"bool"},{"internalType":"address","name":"taker","type":"address"}],"name":"marketOrderFor","outputs":[{"internalType":"uint256","name":"takerGot","type":"uint256"},{"internalType":"uint256","name":"takerGave","type":"uint256"},{"internalType":"uint256","name":"bounty","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"wants","type":"uint256"},{"internalType":"uint256","name":"gives","type":"uint256"},{"internalType":"uint256","name":"gasreq","type":"uint256"},{"internalType":"uint256","name":"gasprice","type":"uint256"},{"internalType":"uint256","name":"pivotId","type":"uint256"}],"name":"newOffer","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"nonces","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"offerDetails","outputs":[{"internalType":"OfferDetail.t","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"offerId","type":"uint256"}],"name":"offerInfo","outputs":[{"components":[{"internalType":"uint256","name":"prev","type":"uint256"},{"internalType":"uint256","name":"next","type":"uint256"},{"internalType":"uint256","name":"wants","type":"uint256"},{"internalType":"uint256","name":"gives","type":"uint256"}],"internalType":"struct OfferStruct","name":"offer","type":"tuple"},{"components":[{"internalType":"address","name":"maker","type":"address"},{"internalType":"uint256","name":"gasreq","type":"uint256"},{"internalType":"uint256","name":"offer_gasbase","type":"uint256"},{"internalType":"uint256","name":"gasprice","type":"uint256"}],"internalType":"struct OfferDetailStruct","name":"offerDetail","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"offers","outputs":[{"internalType":"Offer.t","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"permit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"offerId","type":"uint256"},{"internalType":"bool","name":"deprovision","type":"bool"}],"name":"retractOffer","outputs":[{"internalType":"uint256","name":"provision","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"density","type":"uint256"}],"name":"setDensity","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"fee","type":"uint256"}],"name":"setFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"offer_gasbase","type":"uint256"}],"name":"setGasbase","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"gasmax","type":"uint256"}],"name":"setGasmax","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"gasprice","type":"uint256"}],"name":"setGasprice","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"governanceAddress","type":"address"}],"name":"setGovernance","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"monitor","type":"address"}],"name":"setMonitor","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"notify","type":"bool"}],"name":"setNotify","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"useOracle","type":"bool"}],"name":"setUseOracle","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"vaultAddress","type":"address"}],"name":"setVault","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256[4][]","name":"targets","type":"uint256[4][]"},{"internalType":"bool","name":"fillWants","type":"bool"}],"name":"snipes","outputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256[4][]","name":"targets","type":"uint256[4][]"},{"internalType":"bool","name":"fillWants","type":"bool"},{"internalType":"address","name":"taker","type":"address"}],"name":"snipesFor","outputs":[{"internalType":"uint256","name":"successes","type":"uint256"},{"internalType":"uint256","name":"takerGot","type":"uint256"},{"internalType":"uint256","name":"takerGave","type":"uint256"},{"internalType":"uint256","name":"bounty","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"wants","type":"uint256"},{"internalType":"uint256","name":"gives","type":"uint256"},{"internalType":"uint256","name":"gasreq","type":"uint256"},{"internalType":"uint256","name":"gasprice","type":"uint256"},{"internalType":"uint256","name":"pivotId","type":"uint256"},{"internalType":"uint256","name":"offerId","type":"uint256"}],"name":"updateOffer","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"vault","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"withdraw","outputs":[{"internalType":"bool","name":"noRevert","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"stateMutability":"payable","type":"receive"}]
*/

// SPDX-License-Identifier:	BSD-2-Clause

// SwingingMarketMaker.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity >=0.8.0;
pragma abicoder v2;
import "./IMangrove.sol";

interface IOfferLogic is IMaker {
  ///////////////////
  // MangroveOffer //
  ///////////////////

  /** @notice Events */

  // Log incident (during post trade execution)
  event LogIncident(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint indexed offerId,
    bytes32 reason
  );

  // Offer logic default gas required --value is used in update and new offer if maxUint is given
  function OFR_GASREQ() external returns (uint);

  // returns missing provision on Mangrove, should `offerId` be reposted using `gasreq` and `gasprice` parameters
  // if `offerId` is not in the `outbound_tkn,inbound_tkn` offer list, the totality of the necessary provision is returned
  function getMissingProvision(
    address outbound_tkn,
    address inbound_tkn,
    uint gasreq,
    uint gasprice,
    uint offerId
  ) external view returns (uint);

  // Changing OFR_GASREQ of the logic
  function setGasreq(uint gasreq) external;

  function redeemToken(
    address token,
    address receiver,
    uint amount
  ) external returns (bool success);

  function approveMangrove(address outbound_tkn, uint amount) external;

  function withdrawFromMangrove(address payable receiver, uint amount)
    external
    returns (bool noRevert);

  function newOffer(
    address outbound_tkn, // address of the ERC20 contract managing outbound tokens
    address inbound_tkn, // address of the ERC20 contract managing outbound tokens
    uint wants, // amount of `inbound_tkn` required for full delivery
    uint gives, // max amount of `outbound_tkn` promised by the offer
    uint gasreq, // max gas required by the offer when called. If maxUint256 is used here, default `OFR_GASREQ` will be considered instead
    uint gasprice, // gasprice that should be consider to compute the bounty (Mangrove's gasprice will be used if this value is lower)
    uint pivotId // identifier of an offer in the (`outbound_tkn,inbound_tkn`) Offer List after which the new offer should be inserted (gas cost of insertion will increase if the `pivotId` is far from the actual position of the new offer)
  ) external payable returns (uint offerId);

  function updateOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId,
    uint offerId
  ) external payable; //returns 0 if updateOffer failed (for instance if offer is underprovisioned) otherwise returns `offerId`

  function retractOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId,
    bool deprovision // if set to `true`, `this` contract will receive the remaining provision (in WEI) associated to `offerId`.
  ) external returns (uint received);
}

// SPDX-License-Identifier:	BSD-2-Clause

// IOfferLogicMulti.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity >=0.7.0;
pragma abicoder v2;

import "./IOfferLogic.sol";

interface IOfferLogicMulti is IOfferLogic {
  /** Multi offer specific Events */
  // Offer management
  event NewOwnedOffer(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint indexed offerId,
    address owner
  );

  // user provision on Mangrove has increased
  event CreditMgvUser(address indexed user, uint amount);

  // user provision on Mangrove has decreased
  event DebitMgvUser(address indexed user, uint amount);

  // user token balance on contract has increased
  event CreditUserTokenBalance(
    address indexed user,
    address indexed token,
    uint amount
  );

  // user token balance on contract has decreased
  event DebitUserTokenBalance(
    address indexed user,
    address indexed token,
    uint amount
  );

  function tokenBalance(address token, address owner) external view returns (uint);

  function balanceOnMangrove(address owner) external view returns (uint);

  function offerOwners(
    address reader,
    address outbound_tkn,
    address inbound_tkn,
    uint fromId,
    uint maxOffers
  )
    external
    view
    returns (
      uint nextId,
      uint[] memory offerIds,
      address[] memory __offerOwners
    );

  function ownerOf(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId
  ) external view returns (address owner);

  function depositToken(address token, uint amount)
    external
    returns (
      //override
      bool success
    );

  function fundMangrove() external payable;
}

// SPDX-License-Identifier:	BSD-2-Clause

// SwingingMarketMaker.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity >=0.8.0;
pragma abicoder v2;
import "./IMangrove.sol";

interface IOrderLogic {
  struct TakerOrder {
    address base; //identifying Mangrove market
    address quote;
    bool partialFillNotAllowed; //revert if taker order cannot be filled and resting order failed or is not enabled
    bool selling; // whether this is a selling order (otherwise a buy order)
    uint wants; // if `selling` amount of quote tokens, otherwise amount of base tokens
    uint gives; // if `selling` amount of base tokens, otherwise amount of quote tokens
    bool restingOrder; // whether the complement of the partial fill (if any) should be posted as a resting limit order
    uint retryNumber; // number of times filling the taker order should be retried (0 means 1 attempt).
    uint gasForMarketOrder; // gas limit per market order attempt
    uint blocksToLiveForRestingOrder; // number of blocks the resting order should be allowed to live, 0 means forever
  }

  struct TakerOrderResult {
    uint takerGot;
    uint takerGave;
    uint bounty;
    uint offerId;
  }

  event OrderSummary(
    address indexed base,
    address indexed quote,
    address indexed taker,
    bool selling,
    uint takerGot,
    uint takerGave,
    uint penalty,
    uint restingOrderId
  );

  function expiring(
    address,
    address,
    uint
  ) external returns (uint);

  function take(TakerOrder memory)
    external
    payable
    returns (TakerOrderResult memory);
}

// SPDX-License-Identifier:	BSD-2-Clause

// AccessedControlled.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

contract AccessControlled {
  address public admin;

  constructor(address admin_) {
    require(admin_ != address(0), "accessControlled/0xAdmin");
    admin = admin_;
  }

  modifier onlyCaller(address caller) {
    require(
      caller == address(0) || msg.sender == caller,
      "AccessControlled/Invalid"
    );
    _;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, "AccessControlled/Invalid");
    _;
  }

  function setAdmin(address _admin) external onlyAdmin {
    admin = _admin;
  }
}

// SPDX-License-Identifier:	AGPL-3.0

// MgvReader.sol

// Copyright (C) 2021 Giry SAS.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.10;
pragma abicoder v2;
import {MgvLib as ML, P} from "../MgvLib.sol";

interface MangroveLike {
  function best(address, address) external view returns (uint);

  function offers(
    address,
    address,
    uint
  ) external view returns (P.Offer.t);

  function offerDetails(
    address,
    address,
    uint
  ) external view returns (P.OfferDetail.t);

  function offerInfo(
    address,
    address,
    uint
  ) external view returns (P.OfferStruct memory, P.OfferDetailStruct memory);

  function config(address, address)
    external
    view
    returns (P.Global.t, P.Local.t);
}

contract MgvReader {
  using P.Offer for P.Offer.t;
  using P.Global for P.Global.t;
  using P.Local for P.Local.t;
  MangroveLike immutable mgv;

  constructor(address _mgv) {
    mgv = MangroveLike(payable(_mgv));
  }

  /*
   * Returns two uints.
   *
   * `startId` is the id of the best live offer with id equal or greater than
   * `fromId`, 0 if there is no such offer.
   *
   * `length` is 0 if `startId == 0`. Other it is the number of live offers as good or worse than the offer with
   * id `startId`.
   */
  function offerListEndPoints(
    address outbound_tkn,
    address inbound_tkn,
    uint fromId,
    uint maxOffers
  ) public view returns (uint startId, uint length) {
    unchecked {
      if (fromId == 0) {
        startId = mgv.best(outbound_tkn, inbound_tkn);
      } else {
        startId = mgv.offers(outbound_tkn, inbound_tkn, fromId).gives() > 0
          ? fromId
          : 0;
      }

      uint currentId = startId;

      while (currentId != 0 && length < maxOffers) {
        currentId = mgv.offers(outbound_tkn, inbound_tkn, currentId).next();
        length = length + 1;
      }

      return (startId, length);
    }
  }

  // Returns the orderbook for the outbound_tkn/inbound_tkn pair in packed form. First number is id of next offer (0 is we're done). First array is ids, second is offers (as bytes32), third is offerDetails (as bytes32). Array will be of size `min(# of offers in out/in list, maxOffers)`.
  function packedOfferList(
    address outbound_tkn,
    address inbound_tkn,
    uint fromId,
    uint maxOffers
  )
    public
    view
    returns (
      uint,
      uint[] memory,
      P.Offer.t[] memory,
      P.OfferDetail.t[] memory
    )
  {
    unchecked {
      (uint currentId, uint length) = offerListEndPoints(
        outbound_tkn,
        inbound_tkn,
        fromId,
        maxOffers
      );

      uint[] memory offerIds = new uint[](length);
      P.Offer.t[] memory offers = new P.Offer.t[](length);
      P.OfferDetail.t[] memory details = new P.OfferDetail.t[](length);

      uint i = 0;

      while (currentId != 0 && i < length) {
        offerIds[i] = currentId;
        offers[i] = mgv.offers(outbound_tkn, inbound_tkn, currentId);
        details[i] = mgv.offerDetails(outbound_tkn, inbound_tkn, currentId);
        currentId = offers[i].next();
        i = i + 1;
      }

      return (currentId, offerIds, offers, details);
    }
  }

  // Returns the orderbook for the outbound_tkn/inbound_tkn pair in unpacked form. First number is id of next offer (0 if we're done). First array is ids, second is offers (as structs), third is offerDetails (as structs). Array will be of size `min(# of offers in out/in list, maxOffers)`.
  function offerList(
    address outbound_tkn,
    address inbound_tkn,
    uint fromId,
    uint maxOffers
  )
    public
    view
    returns (
      uint,
      uint[] memory,
      P.OfferStruct[] memory,
      P.OfferDetailStruct[] memory
    )
  {
    unchecked {
      (uint currentId, uint length) = offerListEndPoints(
        outbound_tkn,
        inbound_tkn,
        fromId,
        maxOffers
      );

      uint[] memory offerIds = new uint[](length);
      P.OfferStruct[] memory offers = new P.OfferStruct[](length);
      P.OfferDetailStruct[] memory details = new P.OfferDetailStruct[](length);

      uint i = 0;
      while (currentId != 0 && i < length) {
        offerIds[i] = currentId;
        (offers[i], details[i]) = mgv.offerInfo(
          outbound_tkn,
          inbound_tkn,
          currentId
        );
        currentId = offers[i].next;
        i = i + 1;
      }

      return (currentId, offerIds, offers, details);
    }
  }

  function getProvision(
    address outbound_tkn,
    address inbound_tkn,
    uint ofr_gasreq,
    uint ofr_gasprice
  ) external view returns (uint) {
    unchecked {
      (P.Global.t global, P.Local.t local) = mgv.config(
        outbound_tkn,
        inbound_tkn
      );
      uint _gp;
      uint global_gasprice = global.gasprice();
      if (global_gasprice > ofr_gasprice) {
        _gp = global_gasprice;
      } else {
        _gp = ofr_gasprice;
      }
      return (ofr_gasreq + local.offer_gasbase()) * _gp * 10**9;
    }
  }
}