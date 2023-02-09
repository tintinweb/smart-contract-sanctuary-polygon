/**
 *Submitted for verification at polygonscan.com on 2023-02-08
*/

// File: contracts/OTP.sol


pragma solidity >=0.7.5 <0.9.0;


contract OTP {

    mapping(address => otps) private listOfOtp;
    mapping(address => twoOtps) private listOfPartnerOtp;
    uint private serverAuth;
    address private owner;

    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "YOU ARE NOT AUTHERIZED");
        _;
    }

    struct otps {
        uint _otp;
        address _address;
        uint _exp;
        bool _isUsed;
    }

    struct twoOtps {
        uint _otpOne; //otp one is owner
        uint _otpTwo;  // opt two should be partner
        address _addressOne; // owner address 
        address _addressTwo; // partner address 
        uint _exp; // expery time should be same
        bool _isUsed; //false
    }

    function setOtp(address _add, uint _otp, uint _exp, uint _server) public returns(otps memory) {
        require(serverAuth == _server, "YOU HAVE NOT PERMISSION");
        listOfOtp[_add] = otps(_otp, _add, _exp, false);
        return  otps(_otp, _add, _exp, false);
    }

    function setTwoOtp(address _add, address _partner, uint _otpOne, uint _otpTwo, uint _exp, uint _server) public returns(twoOtps memory) {
        require(serverAuth == _server, "YOU HAVE NOT PERMISSION");
        listOfPartnerOtp[_add] = twoOtps(_otpOne, _otpTwo, _add, _partner, _exp, false);
        return  twoOtps(_otpOne, _otpTwo, _add, _partner, _exp, false);
    }

    function otpVerified(uint _otp, address _add) external view returns(bool) {
        otps memory otp = listOfOtp[_add];
        require(block.timestamp < otp._exp, "otp expired");
        require(otp._isUsed == false, "otp already used");
        require(otp._otp == _otp, "opt invalid");
        // listOfOtp[_add] = otps(otp._otp, otp._address, otp._exp, true);
        return true;
    }

    function otp2Verified(uint _otp, uint _partnerOtp, address _add, address _partner) external view returns(bool) {
        twoOtps memory twoOtp = listOfPartnerOtp[_add];
        require(twoOtp._addressTwo == _partner, "Partner not found");
        require(block.timestamp < twoOtp._exp, "otp expired");
        require(twoOtp._isUsed == false, "otp already used");
        require(twoOtp._otpOne == _otp, "OTP Invalid");
        require(twoOtp._otpTwo == _partnerOtp, "partner OTP Invalid");
        // listOfOtp[_add] = otps(otp._otp, otp._address, otp._exp, true);
        return true;
    }

    function setServer(uint _server) public onlyOwner returns(uint) {
        serverAuth = _server;
        return _server;
    }
}