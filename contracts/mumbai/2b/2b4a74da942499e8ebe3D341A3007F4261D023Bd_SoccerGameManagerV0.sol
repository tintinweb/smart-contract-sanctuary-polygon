/**
 *Submitted for verification at polygonscan.com on 2022-07-09
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: contracts/SoccerGameManager.sol



pragma solidity >=0.7.0 <0.9.0;



interface SoccerCoinInterface {
    function claimReward (address _toWhom, uint256 _amount, uint256 _decimals) external;
}


interface TeamBalanceInterface {
    function transferBalance() external payable;
}


contract SoccerGameManagerV0 is Ownable {


    address teamBalanceAddress = 0x21FE4a02444E272f6493E85ca3CA017f85848E77;
    TeamBalanceInterface teamBalanceInterface = TeamBalanceInterface(teamBalanceAddress);

    address soccerCoinAddress = 0xE2579058E7210587e558B47B817e857e45436BE1;
    SoccerCoinInterface soccerCoinInstance = SoccerCoinInterface(soccerCoinAddress);

    mapping (address => bool) public playersContracts;


    struct History {
        uint256 win;
        uint256 draw;
        uint256 lose;
    }


    mapping(address => bool) public coaches;
    mapping(address => uint256) public trainings;
    mapping(address => History) public history;

    uint256 public playPrice = 1000000000000000000 wei;

    uint256 claimSoc = 5;
    uint256 decimalsSoc = 17;


    string private key;


    function playGame(string memory _key, int256 _playerRating, int256 _enemyRating) public payable returns(uint256) {
        require(keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked(_key)));
        require(msg.value >= playPrice);

        uint256 isWinner = 0; // 1 win 2 lose 0 draw

        if(_playerRating - _enemyRating >= 10){
            isWinner = 1;
        } else if(_playerRating - _enemyRating <= -10){
            isWinner = 2;
        } else {
            isWinner = 0;
        }


        if(!coaches[msg.sender]){
            history[msg.sender] = History(0,0,0);
            coaches[msg.sender] = true;
            trainings[msg.sender] = 0;
        }

        if(isWinner == 1){
            history[msg.sender].win += 1;
            trainings[msg.sender] += 1;
            soccerCoinInstance.claimReward(msg.sender,claimSoc, decimalsSoc);
        } else if(isWinner == 2){
            history[msg.sender].lose += 1;
        } else if(isWinner == 0){
            history[msg.sender].draw += 1;
        }

        transferToBalance();
        return isWinner;
    }


    function isTrainAvailable (address _coach) external returns (bool) {
        require(playersContracts[msg.sender]);
        if(coaches[_coach]){
            if(trainings[_coach] > 0){
                trainings[_coach] -= 1;
                return true;
            } 
        }

        return false;
    }
    // #############################################


    // Setting Functions
    function setPlayPrice (uint256 _newPlayPrice) public onlyOwner {
        playPrice = _newPlayPrice;
    }


    function setSecretKey (string memory _newSecretKey) public onlyOwner {
        key = _newSecretKey;
    }


    function setClaimSoc (uint256 _socClaim, uint256 _decimalsSoc) public onlyOwner {
        claimSoc = _socClaim;
        decimalsSoc = _decimalsSoc;
    }


    function approveContract(address _newAddress) public onlyOwner {
        playersContracts[_newAddress] = true;
    }


    function disapproveContract(address _oldAddress) public onlyOwner {
        playersContracts[_oldAddress] = false;
    }
    // ###############################################


    // ########## Manage Finance ##########
    function transferToBalance() internal {
        teamBalanceInterface.transferBalance{value: (address(this).balance)}();
    }
}