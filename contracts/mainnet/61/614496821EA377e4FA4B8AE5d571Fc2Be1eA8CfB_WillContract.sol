// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract WillContract is Ownable, ReentrancyGuard {
  mapping(address => Will) private wills;
  mapping(address => address[]) private memberships;
  mapping(address => bool) private paidDistributionFee;

  uint256 private defaultRenewalRate = 365 days;
  uint256 private creationFee = 0.01 ether;
  uint256 private constant BEQUEST_FEE_DIVISOR = 200; // 0.5%

  struct Will {
    address owner;
    address[] recipients;
    uint256 timestamp;
    uint256 renewalRate;
    IERC20[] tokens;
    uint256[] percentages;
    IERC165[] nfts;
    uint256[] nftIds;
    address[] nftRecipients;
  }

  //###################### Modifiers and Checkers ######################//

  /*
   * @notice ensures function is only called by a will owner
   */
  function isOwner(address _owner) public view returns (bool) {
    return wills[_owner].owner == _owner;
  }

  /*
   * @notice Ensures _recipient is a recipient of the _owner's will
   * @param _owner: will owner's address
   * @param _recipient: address whose membership in the owner's
   * will is being checked
   * @returns true if _recipient is a recipient in _owner's will,
   * false otherwise
   */
  function isRecipient(address _owner, address _recipient)
    public
    view
    returns (bool)
  {
    address[] memory _membership = memberships[_recipient];

    for (uint256 i; i < _membership.length; i++) {
      if (_membership[i] == _owner) {
        return true;
      }
    }
    return false;
  }

  //###################### Internal Functions ######################//

  /*
   * @notice distributes tokens to will recipients by percentage alloted
   * @dev called by distribute function
   * @param _owner: will being distributed's owner's address
   * @param _recipient: address of current recipient
   * @param _percentage: percentage alloted to current recipient
   * @param _percentageSum: sum of allotments already distributed
   * @dev _percentageSum implemented in distribution fxn to ensure correct
   * token value being distributed
   */
  function safeSendBatch(
    address _owner,
    address _recipient,
    uint256 _percentage,
    uint256 _percentageSum
  ) internal {
    Will memory will = wills[_owner];

    for (uint256 i; i < will.tokens.length; i++) {
      uint256 amount = min(
        getTokenAllowance(will.owner, will.tokens[i]),
        getBalance(will.owner, will.tokens[i])
      );

      uint256 share = (_percentage * amount) / _percentageSum;

      if (share != 0) {
        try will.tokens[i].transferFrom(_owner, _recipient, share) {} catch (
          bytes memory
        ) {}
      }
    }
  }

  /*
   * @notice distributes NFTs to will recipients
   * @dev called by distribute function
   * @param _owner: will being distributed's owner's address
   * @param _nfts: list of IERC165s approved in _owner's will
   * @param _recipients: nft recipients from _owner's will
   * @dev only ERC721 and ERC1155's supported
   */
  function safeSendNFTs(
    address _owner,
    address _recipient,
    IERC165[] memory _nfts,
    address[] memory _nftRecipients
  ) internal {
    for (uint256 i; i < _nftRecipients.length; i++) {
      if (_nftRecipients[i] == _recipient) {
        if (_nfts[i].supportsInterface(0x80ac58cd)) {
          IERC721 nft = IERC721(address(_nfts[i]));
          bool canTransfer;

          try nft.ownerOf(wills[_owner].nftIds[i]) returns (address owner) {
            canTransfer = owner == _owner;
          } catch (bytes memory) {}
          try nft.getApproved(wills[_owner].nftIds[i]) returns (
            address approved
          ) {
            canTransfer = canTransfer && approved == address(this);
          } catch (bytes memory) {
            canTransfer = false;
          }
          if (canTransfer) {
            try
              nft.safeTransferFrom(_owner, _recipient, wills[_owner].nftIds[i])
            {} catch (bytes memory) {}
          }
        } else if (_nfts[i].supportsInterface(0xd9b67a26)) {
          IERC1155 nft = IERC1155(address(_nfts[i]));
          uint256 nftBalance;

          try nft.balanceOf(_owner, wills[_owner].nftIds[i]) returns (
            uint256 balance
          ) {
            nftBalance = balance;
          } catch (bytes memory) {}

          try nft.isApprovedForAll(_owner, _recipient) returns (bool approved) {
            if (!approved) {
              nftBalance = 0;
            }
          } catch (bytes memory) {
            nftBalance = 0;
          }

          if (nftBalance > 0) {
            try
              nft.safeTransferFrom(
                _owner,
                msg.sender,
                wills[_owner].nftIds[i],
                nftBalance,
                ""
              )
            {} catch (bytes memory) {}
          }
        }
        delete wills[_owner].nftRecipients[i];
      }
    }
  }

  /*
   * @notice get contract's allowance over a specified token for a specified address
   * @param _owner: token owner's address
   * @param _token: specified token
   * @returns number of tokens for which contract has allowance
   */
  function getTokenAllowance(address _owner, IERC20 _token)
    internal
    view
    returns (uint256)
  {
    try _token.allowance(_owner, address(this)) returns (uint256 allowance) {
      return allowance;
    } catch (bytes memory) {
      return 0;
    }
  }

  /*
   * @notice get address' balance of a specified token
   * @param _owner: token owner's address
   * @param _token: specified token
   * @dev implemented in distribution function, uses try-catch to avoid
   * distribution fxn failure
   * @returns number of tokens _owner possesses
   */
  function getBalance(address _owner, IERC20 _token)
    internal
    view
    returns (uint256)
  {
    try _token.balanceOf(_owner) returns (uint256 balance) {
      return balance;
    } catch (bytes memory) {
      return 0;
    }
  }

  /*
   * @notice get smaller integer between two integers
   * @param a: first integer
   * @param b: second integer
   * @returns smaller integer
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a <= b ? a : b;
  }

  //###################### onlyOwner Functions ######################//

  /*
   * @notice allows contract owner to modify fee taken upon will creation (per additional
   * chain added to will)
   * @param _fee: new fee amount in ether
   */
  function setCreationFee(uint256 _fee) public onlyOwner {
    creationFee = _fee;
  }

  /*
   * @notice lets contract owner to extract fees paid by users upon will creation
   */
  function extractFees() public onlyOwner {
    (bool success, ) = owner().call{ value: address(this).balance }("");
    require(success, "Transaction failed");
  }

  //###################### isOwner Functions ######################//

  /*
   * @notice lets user view their will struct
   * @returns the caller's will and its creation fee
   */
  function getWill(address _owner) public view returns (Will memory, uint256) {
    return (wills[_owner], creationFee);
  }

  /*
    * @notice lets will owner modify their will's renewal rate
    # @param _rate: new renewal rate
    */
  function setRenewalRate(uint256 _rate) public {
    require(isOwner(msg.sender), "Not owner");
    wills[msg.sender].renewalRate = _rate;
    wills[msg.sender].timestamp = block.timestamp;
  }

  /*
   * @notice lets user reset their Dead Man's Switch so will does not become claimable
   */
  function renewWill() public {
    require(isOwner(msg.sender), "Not owner");
    wills[msg.sender].timestamp = block.timestamp;
  }

  /*
   * @notice lets will owner set their will's token recipients (not for NFTs)
   * @param _recipients: token recipients
   * @param _percentages: percentage alloted to each recipient by index match
   */
  function setRecipients(
    address[] memory _recipients,
    uint256[] memory _percentages
  ) public {
    require(isOwner(msg.sender), "Not owner");

    for (uint256 i; i < _recipients.length; i++) {
      for (uint256 j = i + 1; j < _recipients.length; j++) {
        if (_recipients[i] == _recipients[j]) {
          revert("Invalid input");
        }
      }
    }

    require(_recipients.length == _percentages.length, "Invalid input");

    uint256 sum;
    for (uint256 i; i < _percentages.length; i++) {
      sum += _percentages[i];
    }
    require(sum == 100, "Invalid input");

    address[] memory oldRecipients = wills[msg.sender].recipients;

    for (uint256 i; i < oldRecipients.length; i++) {
      address[] memory newMemberships = new address[](
        memberships[oldRecipients[i]].length - 1
      );
      uint256 index = 0;
      for (uint256 j; j < memberships[oldRecipients[i]].length; j++) {
        if (memberships[oldRecipients[i]][j] != msg.sender) {
          newMemberships[index] = memberships[oldRecipients[i]][j];
          index++;
        }
      }
      memberships[oldRecipients[i]] = newMemberships;
    }

    for (uint256 i; i < _recipients.length; i++) {
      memberships[_recipients[i]].push(msg.sender);
    }

    wills[msg.sender].recipients = _recipients;
    wills[msg.sender].percentages = _percentages;
    wills[msg.sender].timestamp = block.timestamp;
  }

  /*
   * @notice sets recipients, tokens, and renewal rate for a will
   * @param _recipients: list of token recipients
   * @param _percentages: percentage alloted to recipient by index match
   * @param _tokens: IERC20 tokens approved to will
   * @param _renewal_rate: new Dead Man's Switch renewal rate
   */

  function setWill(
    address[] memory _recipients,
    uint256[] memory _percentages,
    IERC20[] memory _tokens,
    uint256 _renewalRate
  ) external {
    setRecipients(_recipients, _percentages);
    wills[msg.sender].tokens = _tokens;
    wills[msg.sender].renewalRate = _renewalRate;
  }

  /*
   * @notice lets will owner modify the tokens approved in their will
   * @param _tokens: list of approved IERC20 tokens
   * @dev approval handled by frontend
   */
  function setTokens(IERC20[] memory _tokens) public {
    require(isOwner(msg.sender), "Not owner");
    wills[msg.sender].tokens = _tokens;
    wills[msg.sender].timestamp = block.timestamp;
  }

  /*
   * @notice lets will owner modify the NFTs approved in their will
   * @param _nfts: list of IERC165 supporting nft addresses approved to will
   * @param _nftIds: nft Ids for _nfts, index-matched
   * @param _nftRecipients: list of recipients for the _nfts, index-matched
   */
  function setNFT(
    IERC165[] memory _nfts,
    uint256[] memory _nftIds,
    address[] memory _nftRecipients
  ) public {
    require(isOwner(msg.sender), "Not owner");
    require(_nfts.length == _nftRecipients.length, "Invalid input");
    require(_nfts.length == _nftIds.length, "Invalid input");

    for (uint256 i; i < _nfts.length; i++) {
      require(
        _nfts[i].supportsInterface(0x80ac58cd) ||
          _nfts[i].supportsInterface(0xd9b67a26),
        "Must be ERC721 or ERC1155"
      );
    }

    address[] memory oldRecipients = wills[msg.sender].recipients;

    for (uint256 i; i < oldRecipients.length; i++) {
      address[] memory newMemberships = new address[](
        memberships[oldRecipients[i]].length - 1
      );
      uint256 index = 0;
      for (uint256 j; j < memberships[oldRecipients[i]].length; j++) {
        if (memberships[oldRecipients[i]][j] != msg.sender) {
          newMemberships[index] = memberships[oldRecipients[i]][j];
          index++;
        }
      }
      memberships[oldRecipients[i]] = newMemberships;
    }

    for (uint256 i; i < _nftRecipients.length; i++) {
      memberships[_nftRecipients[i]].push(msg.sender);
    }

    Will storage will = wills[msg.sender];
    will.nfts = _nfts;
    will.nftIds = _nftIds;
    will.nftRecipients = _nftRecipients;
    will.timestamp = block.timestamp;
  }

  //###################### is Recipient Functions ######################//

  /*
   * @notice verifies that caller is recipient and transfers them their token and NFT allotments
   * @param _owner: address of will owner for will being distributed
   */
  function distribute(address _owner, address _recipient)
    external
    nonReentrant
  {
    require(isRecipient(_owner, _recipient), "Not recipient");
    require(
      block.timestamp > wills[_owner].timestamp + wills[_owner].renewalRate,
      "Cannot distribute"
    );

    if (wills[_owner].recipients.length != 0) {
      if (!paidDistributionFee[_owner]) {
        safeSendBatch(wills[_owner].owner, owner(), 1, BEQUEST_FEE_DIVISOR);
        paidDistributionFee[_owner] = true;
      }

      uint256 recipientPercentage;
      uint256 index;

      for (uint256 i; i < wills[_owner].recipients.length; i++) {
        if (wills[_owner].recipients[i] == _recipient) {
          recipientPercentage = wills[_owner].percentages[i];
          index = i;
          break;
        }
      }

      uint256 cumulativePercentage;

      for (uint256 i; i < wills[_owner].percentages.length; i++) {
        cumulativePercentage += wills[_owner].percentages[i];
      }

      safeSendBatch(
        _owner,
        _recipient,
        recipientPercentage,
        cumulativePercentage
      );

      delete wills[_owner].recipients[index];
      delete wills[_owner].percentages[index];
    }

    address[] memory _nftRecipients = wills[_owner].nftRecipients;
    IERC165[] memory _nfts = wills[_owner].nfts;

    safeSendNFTs(_owner, _recipient, _nfts, _nftRecipients);

    // Delete from membership array
    address[] memory newMemberships = new address[](
      memberships[_recipient].length - 1
    );
    uint256 indexNewMemberships = 0;

    for (uint256 j; j < memberships[_recipient].length; j++) {
      if (memberships[_recipient][j] != _owner) {
        newMemberships[indexNewMemberships] = memberships[_recipient][j];
        indexNewMemberships++;
      }
    }
    memberships[_recipient] = newMemberships;

    for (uint256 i; i < wills[_owner].recipients.length; i++) {
      if (wills[_owner].recipients[i] != address(0)) {
        return;
      }
    }

    for (uint256 i; i < wills[_owner].nftRecipients.length; i++) {
      if (wills[_owner].nftRecipients[i] != address(0)) {
        return;
      }
    }
    delete wills[_owner];
  }

  /*
   * @notice lets a recipient view the wills for which they are a recipient
   * @returns list of wills to which they belong
   */
  function getMemberships(address _recipient)
    public
    view
    returns (Will[] memory)
  {
    address[] memory membership = memberships[_recipient];
    Will[] memory membershipWills = new Will[](membership.length);
    for (uint256 i = 0; i < membership.length; i++) {
      membershipWills[i] = wills[membership[i]];
    }
    return membershipWills;
  }

  //###################### Will Creation Function ######################//

  /*
   * @notice user pays fee per chain and an empty will is created on each chain purchased
   */
  function createWill() public payable {
    require(msg.value == creationFee, "Invalid fee");
    require(!isOwner(msg.sender), "Already owner");

    wills[msg.sender] = Will({
      owner: msg.sender,
      recipients: new address[](0),
      timestamp: block.timestamp,
      renewalRate: defaultRenewalRate,
      tokens: new IERC20[](0),
      percentages: new uint256[](0),
      nfts: new IERC165[](0),
      nftIds: new uint256[](0),
      nftRecipients: new address[](0)
    });
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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