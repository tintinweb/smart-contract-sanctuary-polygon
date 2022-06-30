/**
 *Submitted for verification at polygonscan.com on 2022-06-29
*/

// File: kofo/solidity-common/contracts/common/Logger.sol

pragma solidity >=0.5.0 <0.7.0;



/**
 * 调用数据记录
 */
contract Logger {
    modifier note {
        _;
        assembly {
            let mark := msize
            mstore(0x40, add(mark, 288))
            mstore(mark, 0x20)
            mstore(add(mark, 0x20), 224)
            calldatacopy(add(mark, 0x40), 0, 224)
            log4(mark, 288,                             // calldata
            shl(224, shr(224, calldataload(0))),        // msg.sig
            caller,                                     // msg.sender
            calldataload(4),                            // arg1
            calldataload(36)                            // arg2
            )
        }
    }


    event Note(bytes4 indexed sig, address indexed sender, bytes32 indexed arg1, bytes32 indexed arg2, bytes data) anonymous;
}

// File: kofo/solidity-common/contracts/library/Address.sol

pragma solidity >=0.5.0 <0.7.0;


/**
 * 地址工具包
 */
library Address {
    // 地址是否是合约
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;

        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {
            codehash := extcodehash(account)
        }

        return (codehash != 0x0 && codehash != accountHash);
    }

    // 地址转换成payable
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    // 地址转换成bytes32
    function encode(address account) internal pure returns (bytes32 result) {
        bytes memory packed = abi.encode(account);

        assembly {
            result := mload(add(packed, 32))
        }
    }
}

// File: kofo/solidity-common/contracts/test/common/TestLogger.sol

pragma solidity >=0.5.0 <0.7.0;




contract TestLogger is Logger {
    using Address for address;

    function info(address admin, address visitor) public note {
        emit Note(msg.sig, msg.sender, admin.encode(), visitor.encode(), msg.data);
    }
}