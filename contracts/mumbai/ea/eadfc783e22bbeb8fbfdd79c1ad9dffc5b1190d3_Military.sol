// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at a specific moment in the past. If the `clock()` is
     * configured to use block numbers, this will return the value the end of the corresponding block.
     */
    function getPastVotes(address account, uint256 timepoint) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at a specific moment in the past. If the `clock()` is
     * configured to use block numbers, this will return the value the end of the corresponding block.
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 timepoint) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external;
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { ICharacter as IChar } from "./interfaces/ICharacter.sol";
import { IGold } from "./interfaces/IGold.sol";
import { IMilitary } from "./interfaces/IMilitary.sol";

contract Military is IMilitary {
    uint256 public constant PRECISION = 1e18;

    IChar public immutable _char;
    address public immutable _bank;

    uint256 public _totalPower;
    uint256 public _lastUpdate;
    uint256 public _goldPerPower = 1;
    uint256 public _firstExpiringDeposit;
    uint256 public _totalDeposited;

    mapping(uint256 => uint256) public _goldPerPowerByCharId;
    Deposit[] public _deposits;

    modifier onlyCharacter() {
        _onlyCharacter();
        _;
    }

    constructor(IChar character_, address bank_) {
        _char = character_;
        _bank = bank_;
    }

    function deposit(uint256 amount_) external override {
        if (msg.sender != _bank) revert NotBankError(msg.sender);
        if (_firstExpiringDeposit != 0) _updateExpiredDeposits();
        else _lastUpdate = block.timestamp;

        _deposits.push(Deposit({ amount: uint104(amount_), expireTimestamp: uint64(block.timestamp + 365 days) }));
        _totalDeposited += amount_;

        emit Deposited(amount_, block.timestamp + 365 days);
        emit TotalDepositedUpdated(_totalDeposited);
    }

    function join(uint256 charId_) external override {
        if (isCharEnlisted(charId_)) revert AlreadyEnlistedError(charId_);
        (IChar.CharInfo memory charInfo_, address owner_) = _char.getCharInfo(charId_);
        _validateCharOwner(charId_, owner_);

        uint256 goldPerPower_ = _updateExpiredDeposits();
        _goldPerPowerByCharId[charId_] = goldPerPower_;
        _totalPower += charInfo_.power;

        emit TotalPowerUpdated(charInfo_.power);
        emit GoldPerPowerUpdated(goldPerPower_);
        emit GoldPerPowerofCharUpdated(charId_, goldPerPower_);
        emit Joined(charId_, charInfo_.power);
    }

    function leave(uint256 charId_) external override returns (uint256) {
        (IChar.CharInfo memory charInfo_, address owner_) = _char.getCharInfo(charId_);
        _validateCharOwner(charId_, owner_);
        return _leave(charId_, owner_, charInfo_.power);
    }

    function leave(uint256 charId_, address owner_, uint256 charPower_) external override onlyCharacter {
        _leave(charId_, owner_, charPower_);
    }

    function increasePower(uint256 charId_, address owner_, uint256 oldPower_, uint256 powerIncrease_)
        external
        override
        onlyCharacter
    {
        uint256 goldPerPowerOfChar_ = _goldPerPowerByCharId[charId_];
        if (goldPerPowerOfChar_ == 0) return;

        uint256 goldPerPower_ = _updateExpiredDeposits();

        uint256 rewards_ = (goldPerPower_ - goldPerPowerOfChar_) * oldPower_ / PRECISION;
        if (rewards_ != 0) IGold(_bank).transfer(owner_, rewards_);

        _totalPower += powerIncrease_;

        emit RewardsClaimed(charId_, rewards_);
        emit PowerIncreased(charId_, powerIncrease_);
        emit TotalPowerUpdated(oldPower_ + powerIncrease_);
    }

    function getRewards(uint256 charId_) external override returns (uint256 rewards_) {
        (IChar.CharInfo memory charInfo_, address owner_) = _char.getCharInfo(charId_);
        _validateCharOwner(charId_, owner_);

        uint256 goldPerPowerOfChar_ = _goldPerPowerByCharId[charId_];
        if (goldPerPowerOfChar_ == 0) return 0;

        uint256 goldPerPower_ = _updateExpiredDeposits();
        _goldPerPowerByCharId[charId_] = goldPerPower_;

        rewards_ = (goldPerPower_ - goldPerPowerOfChar_) * charInfo_.power / PRECISION;
        if (rewards_ != 0) IGold(_bank).transfer(owner_, rewards_);

        emit GoldPerPowerofCharUpdated(charId_, goldPerPower_);
        emit RewardsClaimed(charId_, rewards_);
    }

    function previewRewards(uint256 charId_) external view override returns (uint256) {
        (IChar.CharInfo memory charInfo_,) = _char.getCharInfo(charId_);
        (,, uint256 goldPerPower_,,) = _checkExpiredDeposits();
        uint256 goldPerPowerOfChar_ = _goldPerPowerByCharId[charId_];

        return (goldPerPower_ - goldPerPowerOfChar_) * charInfo_.power / PRECISION;
    }

    function isCharEnlisted(uint256 charId_) public view override returns (bool) {
        return _goldPerPowerByCharId[charId_] > 0;
    }

    function _leave(uint256 charId_, address owner_, uint256 charPower_) internal returns (uint256 rewards_) {
        uint256 goldPerPowerOfChar_ = _goldPerPowerByCharId[charId_];
        if (goldPerPowerOfChar_ == 0) return 0;

        uint256 goldPerPower_ = _updateExpiredDeposits();
        _totalPower -= charPower_;
        delete _goldPerPowerByCharId[charId_];

        rewards_ = (goldPerPower_ - goldPerPowerOfChar_) * charPower_ / PRECISION;
        if (rewards_ != 0) IGold(_bank).transfer(owner_, rewards_);

        emit GoldPerPowerofCharUpdated(charId_, 0);
        emit RewardsClaimed(charId_, rewards_);
    }

    function _validateCharOwner(uint256 charId_, address owner_) internal view {
        if (owner_ != msg.sender) revert NotCharOwnerError(charId_, msg.sender);
    }

    function _onlyCharacter() internal view {
        if (address(_char) != msg.sender) revert NotCharacterError(msg.sender);
    }

    function _checkExpiredDeposits()
        internal
        view
        returns (
            uint256 totalDeposited_,
            uint256 firstExpiringDeposit_,
            uint256 goldPerPower_,
            uint256 lastUpdate_,
            uint256 goldToburn_
        )
    {
        firstExpiringDeposit_ = _firstExpiringDeposit;
        lastUpdate_ = _lastUpdate;
        totalDeposited_ = _totalDeposited;
        goldPerPower_ = _goldPerPower;
        uint256 totalPower_ = _totalPower;
        uint256 depositsLength_ = _deposits.length;
        if (
            firstExpiringDeposit_ >= depositsLength_
                || _deposits[firstExpiringDeposit_].expireTimestamp > block.timestamp
        ) {
            if (totalPower_ == 0) {
                goldToburn_ = (block.timestamp - lastUpdate_) * totalDeposited_ / 365 days;
            } else {
                goldPerPower_ += (block.timestamp - lastUpdate_) * totalDeposited_ * PRECISION / totalPower_ / 365 days;
            }
            lastUpdate_ = block.timestamp;
            return (totalDeposited_, firstExpiringDeposit_, goldPerPower_, lastUpdate_, goldToburn_);
        }

        do {
            Deposit memory deposit_ = _deposits[firstExpiringDeposit_];
            if (deposit_.expireTimestamp > block.timestamp) break;
            if (totalPower_ == 0) {
                goldToburn_ += (block.timestamp - lastUpdate_) * totalDeposited_ / 365 days;
            } else {
                goldPerPower_ += (block.timestamp - lastUpdate_) * totalDeposited_ * PRECISION / totalPower_ / 365 days;
            }
            lastUpdate_ = deposit_.expireTimestamp;
            unchecked {
                totalDeposited_ -= deposit_.amount;
                ++firstExpiringDeposit_;
            }
        } while (firstExpiringDeposit_ < depositsLength_);

        if (totalPower_ == 0) {
            goldToburn_ += (block.timestamp - lastUpdate_) * totalDeposited_ / 365 days;
        } else {
            goldPerPower_ += (block.timestamp - lastUpdate_) * totalDeposited_ * PRECISION / totalPower_ / 365 days;
        }
    }

    function _updateExpiredDeposits() internal returns (uint256 goldPerPower_) {
        uint256 goldToBurn_;
        uint256 firstExpiringDeposit_;
        uint256 totalDeposited_;
        (totalDeposited_, firstExpiringDeposit_, goldPerPower_, _lastUpdate, goldToBurn_) = _checkExpiredDeposits();
        _firstExpiringDeposit = firstExpiringDeposit_;
        _totalDeposited = totalDeposited_;
        _goldPerPower = goldPerPower_;

        if (goldToBurn_ != 0) IGold(_bank).burn(address(this), goldToBurn_);

        emit FirstExpiringDepositUpdated(firstExpiringDeposit_);
        emit GoldPerPowerUpdated(goldPerPower_);
        emit GoldBurned(goldToBurn_);
        emit TotalDepositedUpdated(totalDeposited_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./IOFTCore.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the OFT standard
 */
interface IOFT is IOFTCore, IERC20 { }

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface of the IOFT core standard
 */
interface IOFTCore is IERC165 {
    /**
     * @dev estimate send token `_tokenId` to (`_dstChainId`, `_toAddress`)
     * _dstChainId - L0 defined chain id to send tokens too
     * _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
     * _amount - amount of the tokens to transfer
     * _useZro - indicates to use zro to pay L0 fees
     * _adapterParam - flexible bytes array to indicate messaging adapter services in L0
     */
    function estimateSendFee(
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _amount,
        bool _useZro,
        bytes calldata _adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    /**
     * @dev send `_amount` amount of token to (`_dstChainId`, `_toAddress`) from `_from`
     * `_from` the owner of token
     * `_dstChainId` the destination chain identifier
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_amount` the quantity of tokens in wei
     * `_refundAddress` the address LayerZero refunds if too much message fee is sent
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    /**
     * @dev returns the circulating amount of tokens on current chain
     */
    function circulatingSupply() external view returns (uint256);

    /**
     * @dev returns the address of the ERC20 token
     */
    function token() external view returns (address);

    /**
     * @dev Emitted when `_amount` tokens are moved from the `_sender` to (`_dstChainId`, `_toAddress`)
     * `_nonce` is the outbound nonce
     */
    event SendToChain(uint16 indexed _dstChainId, address indexed _from, bytes _toAddress, uint256 _amount);

    /**
     * @dev Emitted when `_amount` tokens are received from `_srcChainId` into the `_toAddress` on the local chain.
     * `_nonce` is the inbound nonce.
     */
    event ReceiveFromChain(uint16 indexed _srcChainId, address indexed _to, uint256 _amount);

    event SetUseCustomAdapterParams(bool _useCustomAdapterParams);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IVotes } from "@openzeppelin/contracts/governance/utils/IVotes.sol";

interface ICharacter is IERC721, IVotes {
    struct CharInfo {
        uint32 charId;
        uint32 level;
        uint32 power;
        uint160 equippedGold;
    }

    event ItemsEquipped(uint256 indexed charId, uint256[] itemIds);
    event GoldCarried(uint256 indexed charId, uint256 goldAmount);
    event GoldDropped(uint256 indexed charId, uint256 goldAmount);
    event CharacterSent(CharInfo indexed charInfo, uint16 dstChainId, address toAddress);
    event CharacterReceived(CharInfo indexed charInfo, address fromAddress);
    event CharacterLevelUp(uint256 indexed charId, uint32 level);

    error InvalidCharInfoError(CharInfo charInfo);
    error NotOwnerError(address owner);
    error OnlyPortalError(address portal);
    error OnlyBossError(address boss);

    function equipItems(uint256 charId_, uint256[] calldata itemIds_) external;

    function carryGold(uint256 charId_, uint256 goldAmount_) external;

    function dropGold(uint256 charId_, uint256 goldAmount_) external;

    /**
     * @dev send token `_tokenId` to (`_dstChainId`, `_toAddress`) from `_from`
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendFrom(
        address from_,
        uint16 dstChainId_,
        address toAddress_,
        uint256 charId_,
        bytes memory adapterParams_
    ) external payable;

    /**
     * @dev send tokens `_tokenIds[]` to (`_dstChainId`, `_toAddress`) from `_from`
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendBatchFrom(
        address _from,
        uint16 _dstChainId,
        address _toAddress,
        uint256[] calldata charIds_,
        bytes memory adapterParams_
    ) external payable;

    function creditTo(address toAddress_, uint256 tokenId_, bytes memory data_) external;

    function levelUp(uint256 charId_) external;

    function getCharInfo(uint256 charId_) external view returns (CharInfo memory, address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IOFT } from "src/dependencies/layerZero/interfaces/oft/IOFT.sol";

interface IGold is IOFT {
    error NotPrivilegedSender(address sender);
    error NotCharacterError(address sender);

    event GoldBurned(address indexed account, uint256 amount);
    event GoldMinted(address indexed account, uint256 amount);
    event GoldPrivilegedTransfer(address indexed from, address indexed to, uint256 amount);

    function burn(address account_, uint256 amount_) external;
    function mint(address account_, uint256 amount_) external;
    function privilegedTransferFrom(address from_, address to_, uint256 amount_) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { ICharacter as IChar } from "./ICharacter.sol";

interface IMilitary {
    struct Deposit {
        uint192 amount;
        uint64 expireTimestamp;
    }

    struct CharInfo {
        uint224 goldPerPower;
        uint32 power;
    }

    event Deposited(uint256 amount_, uint256 expireTimestamp_);
    event Joined(uint256 indexed charId_, uint256 power_);
    event Left(uint256 indexed charId_, uint256 rewards_);
    event PowerIncreased(uint256 indexed charId_, uint256 powerChange_);
    event TotalPowerUpdated(uint256 totalPower_);
    event FirstExpiringDepositUpdated(uint256 index);
    event GoldPerPowerofCharUpdated(uint256 indexed charId_, uint256 goldPerPower_);
    event GoldPerPowerUpdated(uint256 goldPerPower_);
    event GoldBurned(uint256 amount_);
    event TotalDepositedUpdated(uint256 totalDeposited_);
    event RewardsClaimed(uint256 indexed charId_, uint256 rewards_);

    error NotBankError(address msgSender_);
    error NotCharacterError(address msgSender_);
    error NotCharOwnerError(uint256 charId_, address msgSender_);
    error AlreadyEnlistedError(uint256 charId_);

    function deposit(uint256 amount_) external;

    function join(uint256 charId_) external;

    function leave(uint256 charId_) external returns (uint256 rewards_);

    function leave(uint256 charId_, address owner_, uint256 charPower_) external;

    function increasePower(uint256 charId_, address owner_, uint256 oldPower_, uint256 powerChange_) external;

    function getRewards(uint256 charId_) external returns (uint256 rewards_);

    function previewRewards(uint256 charId_) external view returns (uint256);

    function isCharEnlisted(uint256 charId_) external view returns (bool);
}