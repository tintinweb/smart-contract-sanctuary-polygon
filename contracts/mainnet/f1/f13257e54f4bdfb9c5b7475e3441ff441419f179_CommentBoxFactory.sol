/**
 *Submitted for verification at polygonscan.com on 2022-08-21
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IERC20 {
        function transfer(address _to, uint256 _amount) external returns (bool);
    }

contract CommentBox {
    // boolean, uint, int, address, bytes
    address FactoryContractAddress;
    address NewFactoryContractAddress;
    address Owner;
    string BoxName;
    string BoxDescription;
    uint256 BoxPrice;
    uint256 BoxProgress;
    uint256 BoxGoal;
    
    Comment[] public Comments;
    mapping(string => address) public NameToAddress;
    mapping(address => string) public addressToName;
    mapping(address => string) public addressToTitle;
    mapping(address => string) public addressToComment;
    mapping(address => uint256) public addressToContribution;
    
    struct Comment {
        address PublicKey;
        string Name;
        string Title;
        string Comment;
        uint256 Contribution;
    }

    constructor(address _FactoryContractAddress) {
        Owner = msg.sender;
        FactoryContractAddress = _FactoryContractAddress;
        BoxProgress = 0;
    }

    modifier OnlyOwner() {
        require (msg.sender == Owner, "Not The Owner");
        _;
    }

    function BoxSettings(string memory _BoxName, string memory _BoxDescription, uint256 _BoxPrice, uint256 _BoxGoal) public OnlyOwner {
        BoxName = _BoxName;
        BoxDescription = _BoxDescription;
        BoxPrice = _BoxPrice;
        BoxGoal = _BoxGoal;
    }

    function SetOwner(address _NewOwner) public OnlyOwner {
        Owner = _NewOwner;
    }

    function AddComment(string memory _Name, string memory _Title, string memory _Comment) public payable {
        address _PublicKey = msg.sender;
        uint256 _Contribution = msg.value;
        require (_Contribution >= BoxPrice, "Contribution less than BoxPrice.");
        BoxProgress = BoxProgress + _Contribution;

        Comments.push(Comment(_PublicKey, _Name, _Title, _Comment, _Contribution));
        NameToAddress[_Name] = _PublicKey;
        addressToName[_PublicKey] = _Name;
        addressToTitle[_PublicKey] = _Title;
        addressToComment[_PublicKey] = _Comment;
        addressToContribution[_PublicKey] = _Contribution;
    }
    
    function CheckBoxOwner() public view returns (address){
        return Owner;
    }

    function CheckBoxName() public view returns (string memory){
        return BoxName;
    }

    function CheckBoxDescription() public view returns (string memory){
        return BoxDescription;
    }

    function CheckBoxPrice() public view returns (uint256){
        return BoxPrice;
    }

    function CheckBoxProgress() public view returns (uint256){
        return BoxProgress;
    }

    function CheckBoxGoal() public view returns (uint256){
        return BoxGoal;
    }

    function Withdraw() public OnlyOwner {
        uint256 _accbal = address(this).balance;
        (bool ds, ) = payable(FactoryContractAddress).call{value: _accbal * 1 / 100}("Withdrew %1 to CommentBoxFactory, thank you for using CommentBox!");
        require(ds);
        payable(Owner).transfer(address(this).balance);
    }

    function withdrawToken(address _tokenContract, uint256 _amount) external OnlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(Owner, _amount);
    }

}

contract CommentBoxFactory {
    address FactoryOwner;
    address FactoryContractAddress;
    address NewFactoryContractAddress; // if we upgrade, we will put the new contract address here.
    CommentBox[] public commentBoxArray;

    constructor() {
        FactoryOwner = msg.sender;
        FactoryContractAddress = address(this);
        NewFactoryContractAddress = address(this);
    }

    modifier OnlyFactoryOwner() {
        require (msg.sender == FactoryOwner, "Not The Factory Owner");
        _;
    }

    function SetFactoryOwner(address _NewFactoryOwner) public OnlyFactoryOwner {
        FactoryOwner = _NewFactoryOwner;
    }

    
    function SocialMigration(address _NewFactoryContractAddress) public OnlyFactoryOwner {
        NewFactoryContractAddress = _NewFactoryContractAddress;
    }

    function CreateCommentBox() public {
        CommentBox commentBox = new CommentBox(FactoryContractAddress);
        commentBoxArray.push(commentBox);
    }

    function setBoxSettings(uint256 _commentBoxIndex, string memory _BoxName, string memory _BoxDescription, uint256 _BoxPrice, uint256 _BoxGoal) public {
        commentBoxArray[_commentBoxIndex].BoxSettings(_BoxName, _BoxDescription, _BoxPrice, _BoxGoal);
    }

    function ChangeBoxOwner(uint256 _commentBoxIndex, address _NewOwner) public {
        commentBoxArray[_commentBoxIndex].SetOwner(_NewOwner);
    }

    function AddCommentToBox(uint256 _commentBoxIndex, string memory _Name, string memory _Title, string memory _Comment) public {
        commentBoxArray[_commentBoxIndex].AddComment(_Name, _Title, _Comment);
    }

    function CheckBoxOwner(uint256 _commentBoxIndex) public view returns (address) {
        return commentBoxArray[_commentBoxIndex].CheckBoxOwner();
    }

    function CheckBoxName(uint256 _commentBoxIndex) public view returns (string memory) {
        return commentBoxArray[_commentBoxIndex].CheckBoxName();
    }

    function CheckBoxDescription(uint256 _commentBoxIndex) public view returns (string memory) {
        return commentBoxArray[_commentBoxIndex].CheckBoxDescription();
    }

    function CheckBoxPrice(uint256 _commentBoxIndex) public view returns (uint256) {
        return commentBoxArray[_commentBoxIndex].CheckBoxPrice();
    }

    function CheckBoxProgress(uint256 _commentBoxIndex) public view returns (uint256) {
        return commentBoxArray[_commentBoxIndex].CheckBoxProgress();
    }

    function CheckBoxGoal(uint256 _commentBoxIndex) public view returns (uint256) {
        return commentBoxArray[_commentBoxIndex].CheckBoxGoal();
    }

    function WithdrawFromBox(uint256 _commentBoxIndex) public {
        commentBoxArray[_commentBoxIndex].Withdraw();
    }

    function WithdrawTokenFromBox(uint256 _commentBoxIndex, address _tokenContract, uint256 _amount) public {
        commentBoxArray[_commentBoxIndex].withdrawToken(_tokenContract, _amount);
    }

    function FactoryWithdraw() public OnlyFactoryOwner {
        payable(FactoryOwner).transfer(address(this).balance);
    }

    function FactoryWithdrawToken(address _tokenContract, uint256 _amount) external OnlyFactoryOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(FactoryOwner, _amount);
    }
}