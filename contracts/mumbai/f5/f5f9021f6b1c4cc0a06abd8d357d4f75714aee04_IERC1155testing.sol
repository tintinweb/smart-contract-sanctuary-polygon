/**
 *Submitted for verification at polygonscan.com on 2022-03-01
*/

pragma solidity ^0.8.0;

interface IERC1155 { 
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
    }
interface ERC1155 {
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;
}



contract IERC1155testing {
    constructor (){}
    function HISONE(IERC1155 _token, address[] calldata _accountlist, uint256 _id, uint256[] calldata _amount) public {
    require(_accountlist.length == _amount.length, "Receivers and Amount different length");    
    for(uint i = 0; i < _accountlist.length; i++) {
        _token.safeTransferFrom(msg.sender, _accountlist[i], _id, _amount[i], "");

    }
}

    function IERC1155transfer(IERC1155 _token, address[] memory _to, uint256[] memory _id, uint256[] memory _amount) public {
        require([_to].length == [_amount].length, "Receivers and Amount different length");
    for(uint256 i = 0; i < _to.length; i++) {
        _token.safeTransferFrom(msg.sender, _to[i], _id[i], _amount[i], "");
    }}

    function IERC1155BatchTransfer(IERC1155 _token, address[] memory _to, uint256[] memory _ids, uint256[] memory _amounts) public {
        require(_to.length == _amounts.length, "Receivers and Amount different length");
        for(uint256 i = 0; i < _to.length; i++) {
            _token.safeBatchTransferFrom(msg.sender, _to[i], _ids, _amounts, "");
        }
    }

    function mintBatch(ERC1155 _token, address[] memory _accountlist, uint256[] memory _id, uint256[] memory _amount) public {
    require(_accountlist.length == _amount.length, "Receivers and Amount different length");    
    for(uint i = 0; i < _accountlist.length; i++) {
        _token.mint (_accountlist[i], _id[i], _amount[i], "");

    }

}
    }