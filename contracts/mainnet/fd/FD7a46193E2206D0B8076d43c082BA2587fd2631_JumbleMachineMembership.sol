// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./PriceLists.sol";
import "./StructLib.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

//会員カードの発行
interface IMCC {
  function IssueMembershipCard(
    address to,
    uint8 course,
    uint32 number
  ) external;
}

contract JumbleMachineMembership is Ownable, PriceLists {
  IMCC public MCC;

  uint32 private membershipNumber = 1;
  uint8 private constant FALSE = 1;
  uint8 private constant TRUE = 2;
  uint8 public preOpen = TRUE;
  uint256 public lastdayDiscount;
  uint256 public discountRate;
  uint256 public acceptingMembership = FALSE;
  uint256 public admissionfee = 1 ether;
  mapping(address => StructLib.MembershipInfo) membershipInfos;

  //入会金
  function setAdmissionfee(uint256 newAdmissionfee) external onlyOwner {
    admissionfee = newAdmissionfee;
  }

  //会員募集中
  function setAcceptingMembership(uint256 newState) external onlyOwner {
    acceptingMembership = newState;
  }

  //体験入会
  function trialAdmission(uint8 course) private {
    require(
      membershipInfos[msg.sender].membership == 0,
      "Seems you have joined once in the past."
    );
    registration(msg.sender, course);
  }

  //通常入会
  function admission(uint8 course) external payable {
    require(acceptingMembership == TRUE, "Not accepting new members");
    require(
      membershipInfos[msg.sender].membership != 255,
      "Your address is ban."
    );
    require(
      untilExpiration(msg.sender) <= 0,
      "Your membership is still valid."
    );
    require(priceLists[course].period != 0, "No such course.");

    if (course == 0) {
      trialAdmission(course);
    } else {
      require(
        msg.value >=
          admissionfee + (priceLists[course].cost * discount()) / 100,
        "You don't have enough money for admission."
      );
      registration(msg.sender, course);
    }
  }

  //強制入会
  function forcedAdmission(address address_, uint8 course) external onlyOwner {
    if (untilExpiration(address_) > 0) {
      closeMembership(address_);
    }
    registration(address_, course);
  }

  //登録手続き
  function registration(address address_, uint8 course) private {
    StructLib.MembershipInfo storage info = membershipInfos[address_];
    info.membership = TRUE;
    info.expirationDate = priceLists[course].period + block.timestamp;
    info.appliedCourse = course;

    if (course != 0) {
      info.number = membershipNumber;
      unchecked {
        membershipNumber += 1;
      }
      if (MCC != IMCC(address(0x0))) {
        MCC.IssueMembershipCard(address_, course, info.number);
      }
    }
  }

  //会員カードの設定
  function setMembershipCardContract(address newContractAddress)
    external
    onlyOwner
  {
    MCC = IMCC(newContractAddress);
  }

  //グランドオープン&セール
  function setGrandOpen() external onlyOwner {
    preOpen = FALSE;
    acceptingMembership = TRUE;
    lastdayDiscount = block.timestamp + 7 days;
    discountRate = 50;
  }

  //入会キャンペーン
  function setCampaign(
    uint256 newDiscount,
    uint256 start,
    uint256 periodDiscount
  ) external onlyOwner {
    if (start == 0) {
      start = block.timestamp;
    }
    lastdayDiscount = start + periodDiscount * 1 days;
    discountRate = newDiscount;
  }

  //ディスカウント
  function discount() internal view returns (uint256) {
    if (lastdayDiscount > block.timestamp) {
      return discountRate;
    } else {
      return 100;
    }
  }

  //有効期限の確認
  function untilExpiration(address address_) public view returns (uint256) {
    if (membershipInfos[address_].expirationDate >= block.timestamp) {
      return membershipInfos[address_].expirationDate - block.timestamp;
    } else {
      return 0;
    }
  }

  //退会手続き
  function cancelMembership() external {
    deleteMembership(msg.sender);
  }

  //強制退会手続き
  function closeMembership(address address_) public onlyOwner {
    deleteMembership(address_);
  }

  //退会手続き
  function deleteMembership(address address_) internal {
    membershipInfos[address_].expirationDate = 0;
  }

  //会員を追放する
  function ban(address address_) external onlyOwner {
    deleteMembership(address_);
    membershipInfos[address_].membership = 255;
  }

  //集金
  function withdraw() external onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }

  //募金
  function donations() external payable {}

  //interface用
  function getMembershipInfo(address address_)
    external
    view
    returns (StructLib.MembershipInfo memory)
  {
    return membershipInfos[address_];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

library StructLib {
  struct MembershipInfo {
    uint256 expirationDate;
    uint32 number;
    uint8 appliedCourse;
    uint8 membership;
  }

  struct MembershipCardInfo {
    address address_;
    uint8 appliedCourse;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract PriceLists is Ownable {
  struct PriceList {
    uint64 cost;
    uint64 period;
  }
  mapping(uint8 => PriceList) priceLists;

  constructor() {
    priceLists[0] = PriceList({ cost: 0 ether, period: 3 days }); //Trial
    priceLists[1] = PriceList({ cost: 1 ether, period: 7 days }); //Weekly-Bronze
    priceLists[2] = PriceList({ cost: 2 ether, period: 30 days }); //Monthly-Silver
    priceLists[3] = PriceList({ cost: 3 ether, period: 365 days }); //Annual-Gold
    priceLists[4] = PriceList({ cost: 4 ether, period: 99999 days }); //Perpetual-Platina
  }

  function getPriceList(uint8 index)
    public
    view
    returns (uint64 cost, uint64 period)
  {
    cost = priceLists[index].cost;
    period = priceLists[index].period;
  }

  function setPriceList(
    uint8 index,
    uint64 cost,
    uint64 period
  ) public onlyOwner {
    priceLists[index].cost = cost;
    priceLists[index].period = period;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}