pragma solidity ^0.8.1;

import "../interfaces/IProofOfStorage.sol";
import "../interfaces/IPayments.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CharityPoS {

    IProofOfStorage private posContract;
    IPayments private payContract;
    IERC20 private payToken;

    constructor (address pos_address, address pay_address) {
        posContract = IProofOfStorage(pos_address);
        payContract = IPayments(pay_address);
        payToken = IERC20(pay_address);
    }

    function sendCharityProof(
        address _user_address,
        uint32 _block_number,
        bytes32 _user_root_hash,
        uint64 _user_storage_size,
        uint64 _user_root_hash_nonce,
        bytes calldata _user_signature,
        bytes calldata _file,
        bytes32[] calldata merkleProof
    ) external {

        uint user_reward;
        uint user_balance = payContract.getBalance(_user_address);

        (
            user_reward,
            /* uint time_passed */
        ) = posContract.getUserRewardInfo(_user_address, _user_storage_size);

        if (user_balance < user_reward) {
            uint to_trasfer = user_reward - user_balance;
            require(payContract.getSystemReward() >= to_trasfer, 'Charity: inflation_system_reward < to_trasfer');
            payToken.transferFrom(msg.sender, address(this), to_trasfer);
            payToken.transfer(_user_address, to_trasfer);
        }

        posContract.sendProofFrom(msg.sender, _user_address, _block_number, _user_root_hash, _user_storage_size, _user_root_hash_nonce, _user_signature, _file, merkleProof);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

pragma solidity ^0.8.0;

interface IPayments {
    event ChangePoSContract(address indexed PoS_Contract_Address);
    event RegisterToken(address indexed _token, uint256 indexed _id);

    function getBalance(address _address) external view returns (uint256 result);
    function localTransferFrom(address _from, address _to, uint256 _amount) external;
    function depositToLocal(address _user_address, uint256 _amount) external;
    function closeDeposit(address _user_address) external;
    function getSystemReward() external  view returns (uint256);
}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.9;

interface IProofOfStorage {

    event TargetProofTimeUpdate(
        uint256 _newTargetProofTime
    );

    event MinStorageSizeUpdate(
        uint256 _newMinStorageSize
    );

    /*
        @dev Returns info about user reward for ProofOfStorage

        INPUT
            @_user - User Address
            @_user_storage_size - User Storage Size

        OUTPUT
            @_amount - Total Token Amount for PoS
            @_last_rroof_time - Last Proof Time
    */


    function getUserRewardInfo(address _user, uint _user_storage_size)
        external
        view
        returns (
            uint,
            uint
        );
    
    /*
        @dev Returns last user root hash and nonce.

        INPUT
            @_user - User Address
        
        OUTPUT
            @_hash - Last user root hash
            @_nonce - Noce of root hash
    */
    function getUserRootHash(address _user)
        external
        view
        returns (bytes32, uint);
    
    /**
    * @dev this function update Target Proof time, to move difficulty on same size.
    */
    function setTargetProofTime(uint _newTargetProofTime) external;

    /**
    * @dev this function update Min Storage Size, it means, if min storage size = 500, but 
    * user store less size of data, user storage size will rounding up to 500 MB.
    * it's need's to make mining profitable for prooving small users, but 
    * reward will more, than tx proof cost for miner..
    */
    function setMinStorage(uint _size) external;

    function sendProofFrom(
        address _node_address,
        address _user_address,
        uint32 _block_number,
        bytes32 _user_root_hash,
        uint64 _user_storage_size,
        uint64 _user_root_hash_nonce,
        bytes calldata _user_signature,
        bytes calldata _file,
        bytes32[] calldata merkleProof
    ) external;

}