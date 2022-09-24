/**
 *Submitted for verification at polygonscan.com on 2022-09-23
*/

// File: contracts/TestingContract.sol

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

contract TestingContract {
    bytes constant SIG_PREFIX = "\x19Ethereum Signed Message:\n32";
    address public verifyAddress;

    struct Deposite {
        uint256 amount;
        uint64 monId;
        uint32 classId;
        uint64 _pfpId;
        uint16 _level;
        uint16 _badgeAdvantage;
    }
    event LOG(Deposite _dp);

    constructor() public {
        verifyAddress = msg.sender;
    }

    function setVerifyAddress(address _verifyAddress) external {
        verifyAddress = _verifyAddress;
    }

    function getVerifySignature(address sender, bytes32 _token)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(sender, _token));
    }

    function data(
        bytes32 _token,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        if (verifyAddress == address(0)) revert();
        //This msg.sender is from backend and sent by the owner of the address it used to deteduct gas
        if (getVerifyAddress(msg.sender, _token, _v, _r, _s) != verifyAddress)
            revert();

        Deposite memory dep = extractExpToken(_token);
        emit LOG(dep);
    }

    function getVerifyAddress(
        address sender,
        bytes32 _token,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public pure returns (address) {
        bytes32 hashValue = keccak256(abi.encodePacked(sender, _token));
        bytes32 prefixedHash = keccak256(
            abi.encodePacked(SIG_PREFIX, hashValue)
        );
        return ecrecover(prefixedHash, _v, _r, _s);
    }

    // public
    function extractExpToken(bytes32 _rt)
        public
        view
        returns (Deposite memory)
    {
        // writer.add_uint32(staking_amount)
        // writer.add_uint64(staking_mon)
        // writer.add_uint64(staking_class)
        // writer.add_uint32(staking_pfp)
        // writer.add_uint64(staking_level)
        // writer.add_uint64(staking_badge)
        // writer.add_uint64(nonce1)
        // writer.add_uint64(nonce2)
        Deposite memory dp;
        dp.amount = uint256(_rt >> 384);
        dp.monId = uint64(uint256(_rt >> 320));
        dp.classId = uint32(uint256(_rt >> 256));
        dp._pfpId = uint64(uint256(_rt >> 192));
        dp._level = uint16(uint256(_rt >> 160));
        dp._badgeAdvantage = uint16(uint256(_rt >> 96));
        return dp;
    }
}