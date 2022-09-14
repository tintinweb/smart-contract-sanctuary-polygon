/**
 *Submitted for verification at polygonscan.com on 2022-09-13
*/

pragma solidity 0.8.16;

// SPDX-License-Identifier: MIT

//      ____       _ _______ _           
//     |  _ \     (_)__   __| |          
//     | |_) |_ __ _   | |  | |__   __ _ 
//     |  _ <| '__| |  | |  | '_ \ / _` |
//     | |_) | |  | |  | |  | | | | (_| |
//     |____/|_|  |_|  |_|  |_| |_|\__,_|
//   _____                  _         _____             
//  / ____|                | |       / ____|            
// | |     _ __ _   _ _ __ | |_ ___ | |  __ _   _ _   _ 
// | |    | '__| | | | '_ \| __/ _ \| | |_ | | | | | | |
// | |____| |  | |_| | |_) | || (_) | |__| | |_| | |_| |
//  \_____|_|   \__, | .__/ \__\___/ \_____|\__,_|\__, |
//               __/ | |                           __/ |
//              |___/|_|                          |___/     

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

//Multi-Signature Wallet Used For Distribution Governance of CJ Metaverse Wallet
contract CJMetaEventsWallet {

    address jojo; // Co-owner CJ Meta Evenets: @hombreave17
    address cece; // Co-owner CJ Meta Evenets: @HICeeCee

    bool public jojo_authorization; //Signature Authorization For @hombreave17
    bool public cece_authorization; //Signature Authorization For @HICeeCee

    mapping(IERC20 => bool) public jojo_token_authorization; //Signature Token Authorization For @hombreave17
    mapping(IERC20 => bool) public cece_token_authorization; //Signature Token Authorization For @HICeeCee

    mapping(address => mapping(uint256 => bool)) public jojo_send_authorization; //Signature Send Authorization For @hombreave17
    mapping(address => mapping(uint256 => bool)) public cece_send_authorization; //Signature Send Authorization For @HICeeCee


    //CJMetaEventsWallet: constructor()
    constructor() {

        //Wallet Addresses
        jojo =  0x568BF57B841Cd790ebE7D7E08b68903559A15901; //@hombreave17
        cece = 0x2C7C6E83aE6b0b37D64f3568df668D880dC58A73; //@HICeeCee

        jojo_authorization = false; //Setting Authorization For @hombreave17 To False
        cece_authorization = false; //Setting Authorization For @HICeeCee To False

    }// End constructor()

    //Modifiers

    //onlySigner: Checks If JoJo or CeCe
    modifier onlySigner() {
        // Error -> Unauthorized Signer
        require(msg.sender == jojo || msg.sender == cece, "ERR:US");
        _;
    }//End onlySigner()

    //signatureCheck(): Checks If Both JoJo and CeCe Signed
    modifier signatureCheck() {
        // Error -> Signature Missing
        require(jojo_authorization && cece_authorization, "ERR:SM");
        _;
    }//End signatureCheck()

    //signatureTokenCheck(): Checks If Both JoJo and CeCe Signed For Tokens
    modifier signatureTokenCheck(IERC20 _token) {
        // Error -> Signature Missing
        require(jojo_token_authorization[_token] 
        && cece_token_authorization[_token], "ERR:SM");
        _;
    }//End signatureTokenCheck()

    //signatureSendCheck(): Checks If Both JoJo and CeCe Signed For Send Event
    modifier signatureSendCheck(address _to, uint256 _amount) {
        // Error -> Signature Missing
        require(jojo_send_authorization[_to][_amount] 
        && cece_send_authorization[_to][_amount], "ERR:SM");
        //Error -> Insufficient Balance
        require(address(this).balance >= _amount, "ERR:IB"); 
        _;
    }//End signatureSendCheck()

    //Functions

    //sign(): Signs For Withdraw
    function sign() external onlySigner {

        if (msg.sender == jojo) {
            jojo_authorization = true;
        } else if (msg.sender == cece) {
            cece_authorization = true;
        }

    }//End sign()

    //sign_token(): Signs For Token Withdraw
    function sign_tokens(IERC20 _token) external onlySigner {

        if (msg.sender == jojo) {
            jojo_token_authorization[_token] = true;
        } else if (msg.sender == cece) {
            cece_token_authorization[_token] = true;
        }

    }//End sign_token()

    //sign_send(): Signs For Send Transaction
    function sign_send(address _to, uint256 _amount) external onlySigner {

        if (msg.sender == jojo) {
            jojo_send_authorization[_to][_amount] = true;
        } else if (msg.sender == cece) {
            cece_send_authorization[_to][_amount] = true;
        }

    }//End sign_send()

    //withdraw_matic(): If Both Sign Split Funds
    function withdraw_matic() external onlySigner signatureCheck {

        jojo_authorization = false;
        (bool jo, ) = payable(jojo)
        .call{value: address(this).balance * 50 / 100}("");
        require(jo, "ERR:JR"); //ERR -> Jos Transfer Reverted 

        cece_authorization = false;
        (bool ce, ) = payable(cece)
        .call{value: address(this).balance}("");   
        require(ce, "ERR:CR");//ERR -> Ces Transfer Reverted         

    }//End withdraw_matic()

    //withdraw_token(): If Both Sign Split Tokens
    function withdraw_tokens(IERC20 _token)
    external onlySigner signatureTokenCheck(_token) {

        uint256 jojo_balance = _token.balanceOf(address(this)) * 50 / 100;
        uint256 cece_balance = _token.balanceOf(address(this)) * 50 / 100;
        jojo_token_authorization[_token] = false;
        cece_token_authorization[_token] = false;
        require(_token.transfer(jojo, jojo_balance), "ERR:JT"); //ERR -> Jos Token Reverted 
        require(_token.transfer(cece, cece_balance), "ERR:CT"); //ERR -> Ces Token Reverted    

    }//End withdraw_tokens()
    
    //send_to(): If Both Sign Send Funds
    function send_to(address _to, uint256 _amount) 
    external onlySigner signatureSendCheck(_to, _amount) {
        

        jojo_send_authorization[_to][_amount] = false;
        cece_send_authorization[_to][_amount] = false;

        (bool to, ) = payable(_to)
        .call{value: _amount}("");
        require(to, "ERR:SR"); //ERR -> Send Reverted

    }//End send_to()

}