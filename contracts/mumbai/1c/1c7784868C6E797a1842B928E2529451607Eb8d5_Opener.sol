// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title IMysteryBox
 * @dev Interface for the MysteryBox contract.
 */
interface IMysteryBox {
    /**
     * @dev Retrieves the details of a reward token at the specified index.
     * @param index The index of the reward token
     * @return _type The type of the reward token (NFT or TOKEN)
     * @return _amount_id The amount or ID of the reward token
     * @return dropped A boolean indicating if the reward has been dropped
     * @return _contract The address of the reward token contract
     */
    function rewardTokens(uint index) external view returns (
        uint8 _type,
        uint256 _amount_id,
        bool dropped,
        address _contract
    );

    /**
     * @dev Retrieves the details of a reward NFT at the specified index.
     * @param index The index of the reward NFT
     * @return _type The type of the reward NFT (NFT or TOKEN)
     * @return _amount_id The amount or ID of the reward NFT
     * @return dropped A boolean indicating if the reward has been dropped
     * @return _contract The address of the reward NFT contract
     */
    function rewardNFTs(uint index) external view returns (
        uint8 _type,
        uint256 _amount_id,
        bool dropped,
        address _contract
    );

    /**
     * @dev Adds a reward to the MysteryBox.
     * @param _type The type of the reward (NFT or TOKEN)
     * @param _amount_id The amount or ID of the reward
     * @param _address The address of the reward contract
     */
    function addReward(bool _type, uint256 _amount_id, address _address) external;

    /**
     * @dev Retrieves the initial quantity of keys for the MysteryBox.
     * @return qty The initial quantity of keys
     */
    function initKeyQuantity() external view returns (uint qty);

    /**
     * @dev Retrieves the current quantity of keys for the MysteryBox.
     * @return qty The current quantity of keys
     */
    function currentKeyQuantity() external view returns (uint qty);

    /**
     * @dev Sets the quantity of keys for the MysteryBox.
     */
    function setKeyQuantity() external;

    /**
     * @dev Retrieves the count of reward NFTs in the MysteryBox.
     * @return _nftRewardsCount The count of reward NFTs
     */
    function nftRewardsCount() external view returns (uint _nftRewardsCount);

    /**
     * @dev Retrieves the count of reward tokens in the MysteryBox.
     * @return _tokensCounter The count of reward tokens
     */
    function tokensCounter() external view returns (uint _tokensCounter);

    /**
     * @dev Retrieves the address of the key contract associated with the MysteryBox.
     * @return keyAddress The address of the key contract
     */
    function keyContract() external view returns (address keyAddress);

    /**
     * @dev Transfers a reward NFT from one address to another.
     * @param erc721 The address of the reward NFT contract
     * @param from The address from which to transfer the NFT
     * @param to The address to which to transfer the NFT
     * @param ID The ID of the NFT to transfer
     */
    function transferNFT(address erc721, address from, address to, uint ID) external;

    /**
     * @dev Transfers a quantity of reward tokens from one address to another.
     * @param erc20 The address of the reward token contract
     * @param to The address to which to transfer the tokens
     * @param qty The quantity of tokens to transfer
     */
    function transferTokens(address erc20, address to, uint qty) external;

    /**
     * @dev Updates the amount of a reward token at the specified index.
     * @param index The index of the reward token
     * @param amount The new amount of the reward token
     */
    function updateRewardTokens(uint index, uint amount) external;

    /**
     * @dev Retrieves the count of reward token types in the MysteryBox.
     * @return tokenTypes The count of reward token types
     */
    function tokenRewardsType() external view returns (uint tokenTypes);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IMysteryBox.sol";

/**
 * @title Opener
 * @dev A contract for opening mystery boxes and rewarding users with tokens.
 */
contract Opener {
    using SafeMath for uint256;

    uint256 public percentageDropToken = 30;

    /**
     * @dev Emitted when a specific function is called, providing the gas used for that function.
     * @param func The name of the function.
     * @param gas The amount of gas used.
     */
    event Log(string func, uint256 gas);

    /**
     * @dev Emitted when a token reward is given to the user.
     * @param id_amount The amount of tokens rewarded.
     * @param _contract The address of the token contract.
     */
    event LogTokenReward(uint256 id_amount, address _contract);

    /**
     * @dev Emitted when an NFT reward is given to the user.
     * @param id_amount The amount of NFTs rewarded.
     * @param _contract The address of the NFT contract.
     */
    event LogNFTReward(uint256 id_amount, address _contract);

    /**
     * @dev Emitted when no token reward is available.
     * @param message The message indicating the absence of token reward.
     */
    event LogNoTokenReward(string message);

    /**
     * @dev Emitted when no NFT reward is available.
     * @param message The message indicating the absence of NFT reward.
     */
    event LogNoNFTReward(string message);

    /**
     * @dev Initializes the contract.
     */
    constructor() {}

    /**
     * @dev Generates a random number based on the previous block hash and current timestamp.
     * @param modulo The modulus for generating the random number.
     * @return A random number.
     */
    function random(uint256 modulo) private view returns (uint256) {
        uint256 _random = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp)));
        return _random % modulo;
    }

    /**
     * @dev Opens a mystery box and rewards the user with tokens.
     * @param _mysteryBoxAddress The address of the mystery box contract.
     * @param addressKey The address of the key contract.
     * @param keyID The ID of the key.
     */
    function openBox(address _mysteryBoxAddress, address addressKey, uint256 keyID) public {
        address mysteryKeyAddress = IMysteryBox(_mysteryBoxAddress).keyContract();

        uint256 targetKeyQuantity = IMysteryBox(_mysteryBoxAddress).initKeyQuantity().mul(percentageDropToken).div(100);
        uint256 tokensCounter = IMysteryBox(_mysteryBoxAddress).tokensCounter();
        uint256 tokensQtyRewardTarget = tokensCounter.div(targetKeyQuantity);

        require(
            addressKey == mysteryKeyAddress,
            "wrong key contract address"
        );

        require(
            IERC721(addressKey).ownerOf(keyID) == msg.sender,
            "not owner of this Key"
        );

        IMysteryBox(_mysteryBoxAddress).transferNFT(addressKey, msg.sender, _mysteryBoxAddress, keyID);

        rewardToken(_mysteryBoxAddress, addressKey, keyID, mysteryKeyAddress, tokensQtyRewardTarget);
    }

    /**
     * @dev Rewards the user with tokens based on the outcome.
     * @param _mysteryBoxAddress The address of the mystery box contract.
     * @param addressKey The address of the key contract.
     * @param keyID The ID of the key.
     * @param mysteryKeyAddress The address of the mystery key contract.
     * @param tokensQtyRewardTarget The target quantity of tokens to be rewarded.
     */
    function rewardToken(address _mysteryBoxAddress, address addressKey, uint256 keyID, address mysteryKeyAddress, uint256 tokensQtyRewardTarget) public {
        uint256 indexToken;
        address tokenAddress;
        uint256 randomIndexToken = random(100);
        uint256 tokenTypes = IMysteryBox(_mysteryBoxAddress).tokenRewardsType();

        for (uint256 i = 0; i < tokenTypes; i++) {
            (, uint256 _amount, , address _address) = IMysteryBox(_mysteryBoxAddress).rewardTokens(i);
            if (_amount >= tokensQtyRewardTarget) {
                tokenAddress = _address;
                indexToken = i;
                break;
            }
        }

        if (tokenAddress != address(0) && randomIndexToken <= percentageDropToken) {
            IMysteryBox(_mysteryBoxAddress).transferTokens(tokenAddress, msg.sender, tokensQtyRewardTarget);
            IMysteryBox(_mysteryBoxAddress).updateRewardTokens(indexToken, tokensQtyRewardTarget);
            emit LogTokenReward(tokensQtyRewardTarget, tokenAddress);
        } else {
            emit LogNoTokenReward("TOKEN");
        }
    }

    /**
     * @dev Fallback function that allows the contract to receive ether.
     */
    fallback() external payable {
        emit Log("fallback", gasleft());
    }

    /**
     * @dev Receive function that allows the contract to receive ether when `msg.data` is empty.
     */
    receive() external payable {
        emit Log("receive", gasleft());
    }
}