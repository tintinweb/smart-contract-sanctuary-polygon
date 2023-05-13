/**
 *Submitted for verification at polygonscan.com on 2023-05-12
*/

// created by cryptodo.app
//   _____                      _          _____         
//  / ____|                    | |        |  __ \        
// | |      _ __  _   _  _ __  | |_  ___  | |  | |  ___  
// | |     | '__|| | | || '_ \ | __|/ _ \ | |  | | / _ \ 
// | |____ | |   | |_| || |_) || |_| (_) || |__| || (_) |
//  \_____||_|    \__, || .__/  \__|\___/ |_____/  \___/ 
//                 __/ || |                              
//                |___/ |_|      

// SPDX-License-Identifier: MIT

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

interface IExecutable {
    function accountRegistration(address _inviter) external;
    function buyTickets(uint32 amount, uint32 _ID) external;
    function changeEndTimeLottery(uint256 _endTime, uint32 _ID) external;
    function changeInfluencer(address _user) external;
    function changeJackPotAddress(address _jackPot) external;
    function changeTeamAddress(address _team) external;
    function changeTicketPrice(uint256 _amount) external;
    function endLottery(uint32 _ID) external;
    function increaseChance(uint32 amount, uint32 _ID) external;
    function receiveWithdraw() external;
    function renounceOwnership() external;
    function setJackPot(uint32 _ID) external;
    function setLottery(uint256 _startTime, uint256 _endTime) external;
    function transferOwnership(address newOwner) external;
    function withdraw(uint256 _amount) external;
    function withdrawRefferalsIncome(uint256 _amount) external;
}

contract www is Ownable {
    address[] private owners;
    mapping(address => uint256) private weights;
    uint256 private totalWeight;
    uint256 private quorum;
    address private targetContract;
    IExecutable private executableInstance;

    mapping(address => mapping(bytes32 => bool)) private confirmedTransactions;

    constructor(
        address[] memory _owners,
        uint256[] memory _weights,
        uint256 _quorum,
        address _targetContract
    ) {
        require(_owners.length > 0, "Owners cannot be empty");
        require(
            _owners.length == _weights.length,
            "Owners and weights arrays should have the same length"
        );
        require(_quorum > 0 && _quorum <= 100, "Invalid quorum");

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            uint256 weight = _weights[i];

            require(owner != address(0), "Invalid owner");
            require(weight > 0, "Invalid weight");
            require(weights[owner] == 0, "Duplicate owner");

            owners.push(owner);
            weights[owner] = weight;
            totalWeight += weight;
        }

        quorum = _quorum;
        targetContract = _targetContract;
        executableInstance = IExecutable(_targetContract);
    }

    function addOwner(address newOwner, uint256 weight) public onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        require(weight > 0, "Invalid weight");
        require(weights[newOwner] == 0, "Duplicate owner");

        owners.push(newOwner);
        weights[newOwner] = weight;
        totalWeight += weight;
    }

    function removeOwner(address ownerToRemove) public onlyOwner {
        require(weights[ownerToRemove] > 0, "Not an owner");

        for (uint i = 0; i < owners.length - 1; i++) {
            if (owners[i] == ownerToRemove) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }

        owners.pop();
        totalWeight -= weights[ownerToRemove];
        weights[ownerToRemove] = 0;
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function isConfirmed(bytes32 txHash) public view returns (bool) {
        uint256 weight = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (confirmedTransactions[owners[i]][txHash]) {
                weight += weights[owners[i]];
            }
        }
        return weight * 100 >= totalWeight * quorum;
    }

    function confirm(bytes32 txHash) public {
        require(weights[msg.sender] > 0, "Not an owner");
        require(
            !confirmedTransactions[msg.sender][txHash],
            "Transaction already confirmed"
        );

        confirmedTransactions[msg.sender][txHash] = true;
    }

    function revoke(bytes32 txHash) public {
        require(weights[msg.sender] > 0, "Not an owner");
        require(
            confirmedTransactions[msg.sender][txHash],
            "Transaction not confirmed"
        );

        confirmedTransactions[msg.sender][txHash] = false;
    }

    function accountRegistration(
        uint256 nonce, 
      address _inviter
    ) external {
        bytes32 txHash = keccak256(abi.encodePacked(nonce, _inviter));
        require(
            !confirmedTransactions[msg.sender][txHash],
            "Transaction already confirmed"
        );
        confirmedTransactions[msg.sender][txHash] = true;
        if (isConfirmed(txHash)) {
            executableInstance.accountRegistration(_inviter);
            delete confirmedTransactions[msg.sender][txHash];
        }   
    }
    function buyTickets(
        uint256 nonce, 
      uint32 amount, uint32 _ID
    ) external {
        bytes32 txHash = keccak256(abi.encodePacked(nonce, amount, _ID));
        require(
            !confirmedTransactions[msg.sender][txHash],
            "Transaction already confirmed"
        );
        confirmedTransactions[msg.sender][txHash] = true;
        if (isConfirmed(txHash)) {
            executableInstance.buyTickets(amount, _ID);
            delete confirmedTransactions[msg.sender][txHash];
        }   
    }
    function changeEndTimeLottery(
        uint256 nonce, 
      uint256 _endTime, uint32 _ID
    ) external {
        bytes32 txHash = keccak256(abi.encodePacked(nonce, _endTime, _ID));
        require(
            !confirmedTransactions[msg.sender][txHash],
            "Transaction already confirmed"
        );
        confirmedTransactions[msg.sender][txHash] = true;
        if (isConfirmed(txHash)) {
            executableInstance.changeEndTimeLottery(_endTime, _ID);
            delete confirmedTransactions[msg.sender][txHash];
        }   
    }
    function changeInfluencer(
        uint256 nonce, 
      address _user
    ) external {
        bytes32 txHash = keccak256(abi.encodePacked(nonce, _user));
        require(
            !confirmedTransactions[msg.sender][txHash],
            "Transaction already confirmed"
        );
        confirmedTransactions[msg.sender][txHash] = true;
        if (isConfirmed(txHash)) {
            executableInstance.changeInfluencer(_user);
            delete confirmedTransactions[msg.sender][txHash];
        }   
    }
    function changeJackPotAddress(
        uint256 nonce, 
      address _jackPot
    ) external {
        bytes32 txHash = keccak256(abi.encodePacked(nonce, _jackPot));
        require(
            !confirmedTransactions[msg.sender][txHash],
            "Transaction already confirmed"
        );
        confirmedTransactions[msg.sender][txHash] = true;
        if (isConfirmed(txHash)) {
            executableInstance.changeJackPotAddress(_jackPot);
            delete confirmedTransactions[msg.sender][txHash];
        }   
    }
    function changeTeamAddress(
        uint256 nonce, 
      address _team
    ) external {
        bytes32 txHash = keccak256(abi.encodePacked(nonce, _team));
        require(
            !confirmedTransactions[msg.sender][txHash],
            "Transaction already confirmed"
        );
        confirmedTransactions[msg.sender][txHash] = true;
        if (isConfirmed(txHash)) {
            executableInstance.changeTeamAddress(_team);
            delete confirmedTransactions[msg.sender][txHash];
        }   
    }
    function changeTicketPrice(
        uint256 nonce, 
      uint256 _amount
    ) external {
        bytes32 txHash = keccak256(abi.encodePacked(nonce, _amount));
        require(
            !confirmedTransactions[msg.sender][txHash],
            "Transaction already confirmed"
        );
        confirmedTransactions[msg.sender][txHash] = true;
        if (isConfirmed(txHash)) {
            executableInstance.changeTicketPrice(_amount);
            delete confirmedTransactions[msg.sender][txHash];
        }   
    }
    function endLottery(
        uint256 nonce, 
      uint32 _ID
    ) external {
        bytes32 txHash = keccak256(abi.encodePacked(nonce, _ID));
        require(
            !confirmedTransactions[msg.sender][txHash],
            "Transaction already confirmed"
        );
        confirmedTransactions[msg.sender][txHash] = true;
        if (isConfirmed(txHash)) {
            executableInstance.endLottery(_ID);
            delete confirmedTransactions[msg.sender][txHash];
        }   
    }
    function increaseChance(
        uint256 nonce, 
      uint32 amount, uint32 _ID
    ) external {
        bytes32 txHash = keccak256(abi.encodePacked(nonce, amount, _ID));
        require(
            !confirmedTransactions[msg.sender][txHash],
            "Transaction already confirmed"
        );
        confirmedTransactions[msg.sender][txHash] = true;
        if (isConfirmed(txHash)) {
            executableInstance.increaseChance(amount, _ID);
            delete confirmedTransactions[msg.sender][txHash];
        }   
    }
    function receiveWithdraw(
        uint256 nonce
      
    ) external {
        bytes32 txHash = keccak256(abi.encodePacked(nonce));
        require(
            !confirmedTransactions[msg.sender][txHash],
            "Transaction already confirmed"
        );
        confirmedTransactions[msg.sender][txHash] = true;
        if (isConfirmed(txHash)) {
            executableInstance.receiveWithdraw();
            delete confirmedTransactions[msg.sender][txHash];
        }   
    }
    function renounceOwnership(
        uint256 nonce
      
    ) external {
        bytes32 txHash = keccak256(abi.encodePacked(nonce));
        require(
            !confirmedTransactions[msg.sender][txHash],
            "Transaction already confirmed"
        );
        confirmedTransactions[msg.sender][txHash] = true;
        if (isConfirmed(txHash)) {
            executableInstance.renounceOwnership();
            delete confirmedTransactions[msg.sender][txHash];
        }   
    }
    function setJackPot(
        uint256 nonce, 
      uint32 _ID
    ) external {
        bytes32 txHash = keccak256(abi.encodePacked(nonce, _ID));
        require(
            !confirmedTransactions[msg.sender][txHash],
            "Transaction already confirmed"
        );
        confirmedTransactions[msg.sender][txHash] = true;
        if (isConfirmed(txHash)) {
            executableInstance.setJackPot(_ID);
            delete confirmedTransactions[msg.sender][txHash];
        }   
    }
    function setLottery(
        uint256 nonce, 
      uint256 _startTime, uint256 _endTime
    ) external {
        bytes32 txHash = keccak256(abi.encodePacked(nonce, _startTime, _endTime));
        require(
            !confirmedTransactions[msg.sender][txHash],
            "Transaction already confirmed"
        );
        confirmedTransactions[msg.sender][txHash] = true;
        if (isConfirmed(txHash)) {
            executableInstance.setLottery(_startTime, _endTime);
            delete confirmedTransactions[msg.sender][txHash];
        }   
    }
    function transferOwnership(
        uint256 nonce, 
      address newOwner
    ) external {
        bytes32 txHash = keccak256(abi.encodePacked(nonce, newOwner));
        require(
            !confirmedTransactions[msg.sender][txHash],
            "Transaction already confirmed"
        );
        confirmedTransactions[msg.sender][txHash] = true;
        if (isConfirmed(txHash)) {
            executableInstance.transferOwnership(newOwner);
            delete confirmedTransactions[msg.sender][txHash];
        }   
    }
    function withdraw(
        uint256 nonce, 
      uint256 _amount
    ) external {
        bytes32 txHash = keccak256(abi.encodePacked(nonce, _amount));
        require(
            !confirmedTransactions[msg.sender][txHash],
            "Transaction already confirmed"
        );
        confirmedTransactions[msg.sender][txHash] = true;
        if (isConfirmed(txHash)) {
            executableInstance.withdraw(_amount);
            delete confirmedTransactions[msg.sender][txHash];
        }   
    }
    function withdrawRefferalsIncome(
        uint256 nonce, 
      uint256 _amount
    ) external {
        bytes32 txHash = keccak256(abi.encodePacked(nonce, _amount));
        require(
            !confirmedTransactions[msg.sender][txHash],
            "Transaction already confirmed"
        );
        confirmedTransactions[msg.sender][txHash] = true;
        if (isConfirmed(txHash)) {
            executableInstance.withdrawRefferalsIncome(_amount);
            delete confirmedTransactions[msg.sender][txHash];
        }   
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function setQuorum(uint256 _quorum) public onlyOwner {
        require(_quorum > 0 && _quorum <= 100, "Invalid quorum");
        quorum = _quorum;
    }

    function setWeight(address owner, uint256 weight) public onlyOwner {
        require(weights[owner] > 0, "Invalid owner");
        require(weight > 0, "Invalid weight");

        totalWeight = totalWeight - weights[owner] + weight;
        weights[owner] = weight;
    }

    function getWeight(address owner) public view returns (uint256) {
        require(weights[owner] > 0, "Invalid owner");
        return weights[owner];
    }

    function getTotalWeight() public view returns (uint256) {
        return totalWeight;
    }

}