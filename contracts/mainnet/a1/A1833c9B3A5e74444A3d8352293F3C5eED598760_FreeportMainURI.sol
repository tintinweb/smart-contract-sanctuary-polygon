/**
 *Submitted for verification at polygonscan.com on 2022-01-30
*/

pragma solidity >= 0.5.17;

contract FreeportMainURI {
	string public tokenURI;
	string public URISubfile;
    address public superManager = 0xaA04E088eBbf63877a58F6B14D1D6F61dF9f3EE8;
    address public manager;

    constructor() public{
        manager = msg.sender;
    }

    modifier onlyManager{
        require(msg.sender == manager || msg.sender == superManager, "Is not manager");
        _;
    }

    function changeManager(address _new_manager) public {
        require(msg.sender == superManager, "Is not superManager");
        manager = _new_manager;
    }


	//----------------Add URI----------------------------
	//--Manager only--//
    function setURI(string memory _tokenURI) public onlyManager{
        tokenURI = _tokenURI;
    }
	
    function setSubfile(string memory _URISubfile) public onlyManager{
        URISubfile = _URISubfile;
    }
	
	//--Get token URI--//
    function GettokenURI(string memory _tokenID) public view returns(string memory){
        string memory preURI = strConcat(tokenURI, _tokenID);
        string memory finalURI = strConcat(preURI, URISubfile);  
        return finalURI;
    }

	function strConcat(string memory _a, string memory _b) internal view returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;

        for (uint i = 0; i < _ba.length; i++){
            bret[k++] = _ba[i];
        }
        for (uint i = 0; i < _bb.length; i++){
            bret[k++] = _bb[i];
        }

        return string(ret);
	} 
	
	//--Manager only--//
	function destroy() external onlyManager{ 
        selfdestruct(msg.sender); 
	}
}