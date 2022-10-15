/**
 *Submitted for verification at polygonscan.com on 2022-10-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;


interface XENCrypto {
    function claimMintRewardAndShare(address other, uint256 pct) external;
    function claimRank(uint256 term) external;
    function claimMintReward() external;
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


contract Attack {

    using Address for address;
   
    XENCrypto xen = XENCrypto(0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8);

    address owner;

    constructor() {
        owner = msg.sender;
    }

    fallback() external payable {
        xen.claimRank(1);
    }

    function call(address target, bytes memory data, uint256 value) external returns (bytes memory){
        require(msg.sender == owner);
        return target.functionCallWithValue(data,value,"Error call");
    }


    
}