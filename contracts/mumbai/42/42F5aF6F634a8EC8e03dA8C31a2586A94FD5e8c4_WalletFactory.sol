// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

library CustomErrors {
    error UserNotRegistered();
    error UserAlreadyRegistered();
    error ZeroAmountDeposit();
    error IncorrectSecret();
    error CallFailed();
    error InvalidHash();
    error InvalidMsgSender();
    error ZKPVerificationFailed();
    error InfufficientETHBalance();
    error InvalidCreds();
    error EthTransferFailed();
    error CanNotUseSameProofAgain();
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

library Events {
    event UserRegistered(bytes32 indexed _hash, string indexed _userName,uint256 indexed timestamp);
    event TransferredToSmartWallet(bytes32 indexed from,bytes32 indexed to,uint256 indexed value,uint256 timestamp );
    event TransferredToEOA(bytes32 indexed from,address indexed to,uint256 indexed value,uint256 timestamp );
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {CustomErrors} from "./errors/error.sol";
import {Groth16Verifier} from "./Verifier.sol";
import {Events} from "./events/event.sol";
import {Wallet} from "./Wallet.sol";

// import "hardhat/console.sol";

contract WalletFactory is Groth16Verifier {
    // address public wallet;
    // mapping(bytes32 => uint256) public pswdToBalance;
    mapping(string => bool) public isUserNameTaken;
    mapping(string => bytes32) public usernameToPassword;
    mapping(string => address) public usernameToWalletAddress;
    mapping(bytes32 => bool) public nullifier;

    uint256 public inc;

    error UserNotRegistered();
    error UserAlreadyRegistered();
    error ZeroAmountDeposit();
    error IncorrectSecret();
    error CallFailed();
    error InvalidHash();
    error InvalidMsgSender();
    error ZKPVerificationFailed();
    error InfufficientETHBalance();
    error InvalidCreds();
    error EthTransferFailed();
    error CanNotUseSameProofAgain();

    function registerUser(bytes32 _hash, string memory _userName) public {
        if (isUserNameTaken[_userName]) {
            revert UserAlreadyRegistered();
        }
        isUserNameTaken[_userName] = true;
        usernameToPassword[_userName] = _hash;
        Wallet wallet = new Wallet();
        usernameToWalletAddress[_userName] = address(wallet);

        emit Events.UserRegistered(_hash, _userName, block.timestamp);
    }

    function callWallet(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[2] calldata _pubSignals,
        string calldata _userName,
        bytes[] memory _callData
    ) public {
        bytes32 hash = bytes32(_pubSignals[0]);
        if (_pubSignals[1] != uint256(uint160(msg.sender))) {
            revert InvalidMsgSender();
        }
        // bytes32 pswd = usernameToPassword[_to];
        bytes32 nul = hashMultipleBytes32(_pA, _pB, _pC, _pubSignals);

        if (nullifier[nul]) {
            revert CanNotUseSameProofAgain();
        }
        if (!verifyProof(_pA, _pB, _pC, _pubSignals)) {
            revert ZKPVerificationFailed();
        }

        if ((usernameToPassword[_userName]) != (hash)) {
            revert InvalidCreds();
        }

        // address userWallet = usernameToWalletAddress[_userName];
        Wallet wallet = Wallet(payable(usernameToWalletAddress[_userName]));
        wallet.multicall(_callData);
    }

    function increment(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[2] calldata _pubSignals
    ) public {
        if (!verifyProof(_pA, _pB, _pC, _pubSignals)) {
            revert ZKPVerificationFailed();
        }
        inc++;
    }

    function hashMultipleBytes32(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[2] calldata _pubSignals
    ) internal pure returns (bytes32) {
        bytes memory concatenatedValues = abi.encodePacked(
            _pA[0],
            _pA[1],
            _pB[0][0],
            _pB[0][1],
            _pB[1][0],
            _pB[1][1],
            _pC[0],
            _pC[1],
            _pubSignals[0],
            _pubSignals[1]
        );
        bytes32 hash = keccak256(concatenatedValues);
        return hash;
    }
}

// SPDX-License-Identifier: GPL-3.0
/*
    Copyright 2021 0KIMS association.

    This file is generated with [snarkJS](https://github.com/iden3/snarkjs).

    snarkJS is a free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    snarkJS is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
    License for more details.

    You should have received a copy of the GNU General Public License
    along with snarkJS. If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity =0.8.18;

contract Groth16Verifier {
    // Scalar field size
    uint256 constant r    = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 constant q   = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 constant alphax  = 20491192805390485299153009773594534940189261866228447918068658471970481763042;
    uint256 constant alphay  = 9383485363053290200918347156157836566562967994039712273449902621266178545958;
    uint256 constant betax1  = 4252822878758300859123897981450591353533073413197771768651442665752259397132;
    uint256 constant betax2  = 6375614351688725206403948262868962793625744043794305715222011528459656738731;
    uint256 constant betay1  = 21847035105528745403288232691147584728191162732299865338377159692350059136679;
    uint256 constant betay2  = 10505242626370262277552901082094356697409835680220590971873171140371331206856;
    uint256 constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant deltax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant deltay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant deltay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;

    
    uint256 constant IC0x = 1655549413518972190198478012616802994254462093161203201613599472264958303841;
    uint256 constant IC0y = 21742734017792296281216385119397138748114275727065024271646515586404591497876;
    
    uint256 constant IC1x = 16497930821522159474595176304955625435616718625609462506360632944366974274906;
    uint256 constant IC1y = 10404924572941018678793755094259635830045501866471999610240845041996101882275;
    
    uint256 constant IC2x = 9567910551099174794221497568036631681620409346997815381833929247558241020796;
    uint256 constant IC2y = 17282591858786007768931802126325866705896012606427630592145070155065868649172;
    
 
    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[2] calldata _pubSignals) public view returns (bool) {
        bool isValid;
        assembly {
            function checkField(v) {
                if iszero(lt(v, q)) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }
            
            // G1 function to multiply a G1 value(x,y) to value in an address
            function g1_mulAccC(pR, x, y, s) {
                let success
                let mIn := mload(0x40)
                mstore(mIn, x)
                mstore(add(mIn, 32), y)
                mstore(add(mIn, 64), s)

                success := staticcall(sub(gas(), 2000), 7, mIn, 96, mIn, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }

                mstore(add(mIn, 64), mload(pR))
                mstore(add(mIn, 96), mload(add(pR, 32)))

                success := staticcall(sub(gas(), 2000), 6, mIn, 128, pR, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            function checkPairing(pA, pB, pC, pubSignals, pMem) -> isOk {
                let _pPairing := add(pMem, pPairing)
                let _pVk := add(pMem, pVk)

                mstore(_pVk, IC0x)
                mstore(add(_pVk, 32), IC0y)

                // Compute the linear combination vk_x
                
                g1_mulAccC(_pVk, IC1x, IC1y, calldataload(add(pubSignals, 0)))
                
                g1_mulAccC(_pVk, IC2x, IC2y, calldataload(add(pubSignals, 32)))
                

                // -A
                mstore(_pPairing, calldataload(pA))
                mstore(add(_pPairing, 32), mod(sub(q, calldataload(add(pA, 32))), q))

                // B
                mstore(add(_pPairing, 64), calldataload(pB))
                mstore(add(_pPairing, 96), calldataload(add(pB, 32)))
                mstore(add(_pPairing, 128), calldataload(add(pB, 64)))
                mstore(add(_pPairing, 160), calldataload(add(pB, 96)))

                // alpha1
                mstore(add(_pPairing, 192), alphax)
                mstore(add(_pPairing, 224), alphay)

                // beta2
                mstore(add(_pPairing, 256), betax1)
                mstore(add(_pPairing, 288), betax2)
                mstore(add(_pPairing, 320), betay1)
                mstore(add(_pPairing, 352), betay2)

                // vk_x
                mstore(add(_pPairing, 384), mload(add(pMem, pVk)))
                mstore(add(_pPairing, 416), mload(add(pMem, add(pVk, 32))))


                // gamma2
                mstore(add(_pPairing, 448), gammax1)
                mstore(add(_pPairing, 480), gammax2)
                mstore(add(_pPairing, 512), gammay1)
                mstore(add(_pPairing, 544), gammay2)

                // C
                mstore(add(_pPairing, 576), calldataload(pC))
                mstore(add(_pPairing, 608), calldataload(add(pC, 32)))

                // delta2
                mstore(add(_pPairing, 640), deltax1)
                mstore(add(_pPairing, 672), deltax2)
                mstore(add(_pPairing, 704), deltay1)
                mstore(add(_pPairing, 736), deltay2)


                let success := staticcall(sub(gas(), 2000), 8, _pPairing, 768, _pPairing, 0x20)

                isOk := and(success, mload(_pPairing))
            }

            let pMem := mload(0x40)
            mstore(0x40, add(pMem, pLastMem))

            // Validate that all evaluations ∈ F
            
            checkField(calldataload(add(_pubSignals, 0)))
            
            checkField(calldataload(add(_pubSignals, 32)))
            
            checkField(calldataload(add(_pubSignals, 64)))
            

            // Validate all evaluations
            // let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)
            isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            // mstore(0, isValid)
            //  return(0, 0x20)
         }
         return isValid;
     }
 }

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Wallet is Ownable {
    function multicall(bytes[] memory _data) public payable onlyOwner {
        for (uint256 i = 0; i < _data.length; i++) {
            (address target, uint256 ethValue, bytes memory callData) = abi
                .decode(_data[i], (address, uint256, bytes));
            (bool success, ) = target.call{value: ethValue}(callData);
            require(success, ".call() failed");
        }
    }
    receive() external payable {}
}