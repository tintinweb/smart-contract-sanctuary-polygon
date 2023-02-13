// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./verify.sol";
import "./ReentrancyGuard.sol";
interface IERC20{
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);    
}
contract IDO is Ownable,verify,ReentrancyGuard{

    struct token{
        address projectOwner;
        uint8 status;
        uint256 insurance;
    }
    
    mapping(address => token) public tokenRegistered;                                                       //tokenRegistered[tokenAddress].projectOwner
    mapping(address => mapping(address => uint256)) balances;                                               //balances[tokenAddress][user]
    mapping(bytes => bool) public signatureStatus;
    event tokenRegister(address indexed _token,address indexed _projectOwner);
    event userPayment(address indexed _user,address _token, uint256 _amount);
    function registerToken(address _token,address _projectOwner) public {
        require(owner() == msg.sender,"caller is not permitted to set the token for IDO");
        token memory tk = tokenRegistered[_token];
        tk.projectOwner = _projectOwner;
        tk.status = 1;
        tokenRegistered[_token] = tk;
        emit tokenRegister(_token,_projectOwner);
    }

    /*
        msg.value = insurance + commission + payToProjectOwner
    */
    function purchaseToken(address _user,address _token, uint256 _timeStamp,uint256 _noOfToken, uint256 _insurance,uint256 _commission,uint256 _payToProjectOwner,bytes calldata _signature) public payable{
        bool _status = verifyRegister(owner(), _user,_token,_timeStamp,_noOfToken,_insurance,_commission,_payToProjectOwner,_signature);
        require(_status,"signature doesnot  match");               
        require(!signatureStatus[_signature],"already used signature"); 
        token memory tk = tokenRegistered[_token];
        require(tk.status == 1,"this token is not accepted");
        balances[_token][_user] += _noOfToken;        
        if(_insurance>0){
            tk.insurance += _insurance;
            payable(address(this)).transfer(_insurance);
        }
        payable(owner()).transfer(_commission);
        address _projectOwner = tk.projectOwner;
        payable(_projectOwner).transfer(_payToProjectOwner);
        IERC20(_token).transferFrom(_projectOwner,address(this),_noOfToken);
        signatureStatus[_signature] = true;
        emit userPayment(_user,_token,msg.value);
    }

    function claimToken(address _user,address _token,uint _timeStamp,uint256 _noOfToken,bytes calldata _signature) public{
        bool _status = verifyClaimToken(owner(),_user,_token,_timeStamp,_noOfToken,_signature);
        require(_status,"signature doesnot  match");               
        require(!signatureStatus[_signature],"already used signature");
        _status = IERC20(_token).transfer(_user, _noOfToken);
        require(_status,"transfer Failed");
        balances[_token][_user] -= _noOfToken;
        signatureStatus[_signature] = true;        
    }

    function claimInsurance(address _user,address _token,uint256 _timeStamp, uint256 _amount,bytes calldata _signature) public nonReentrant{
        bool _status = verifyClaimInsurance(owner(),_user,_token,_timeStamp,_amount,_signature);
        require(_status,"signature doesnot  match");               
        require(!signatureStatus[_signature],"already used signature");
        token memory tk = tokenRegistered[_token];
        require(tk.status == 1,"this token is not accepted");
        tk.insurance -= _amount;
        payable(address(_user)).transfer(_amount);
        signatureStatus[_signature] = true;
    }


    function returnInsurance(address _token) public nonReentrant{
        require(owner() == msg.sender,"Only Owner can call be caller");
        token memory tk = tokenRegistered[_token];
        require(tk.status == 1,"No such token exist");        
        payable(tk.projectOwner).transfer(tk.insurance);
        tk.insurance = 0;
        tokenRegistered[_token] = tk;
    }
}