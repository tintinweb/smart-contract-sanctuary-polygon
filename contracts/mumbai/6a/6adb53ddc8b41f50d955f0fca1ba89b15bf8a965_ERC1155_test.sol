// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../ERC1155.sol";
import "../Ownable.sol";
import "../Counters.sol";
import "../Strings.sol";

contract ERC1155_test is ERC1155, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    event Print_Requested(uint256 SFT_Id, uint256 NFT_Id, address token_owner);
    event NFT_Status_Changed(uint256 SFT_Id, uint256 NFT_Id, uint256 status);

    address[] SFT_owners;
    mapping(address => bool) private _isowner;

    mapping (uint256 => mapping(address => uint256[])) private nft_list; //mapping sft to nft: sft_id>owner>[nft_id & status]
        //set a certain status of a specific nft.
        //In the initial setup these would be the status data and thier interpretation:
        //xxxxxxx0 - print disabled
        //xxxxxxx1 - print enabled
        //xxxxxx1x - request pending
        //xxxxx0xx - not printed
        //xxxxx1xx - already printed 

    string private contract_uri = 'https://gateway.pinata.cloud/ipfs/QmXgsTjqii6qGh9Z95bobwm2ck1YTdJy5Fju8SfKbh9TEn';
    string private _uri = 'https://gateway.pinata.cloud/ipfs/QmQ4a2MScjL6cdgczLERUPufL4kE2irwvn4pvXw2dy1Rta/';
    
    constructor() ERC1155(_uri) {
    }
    
    function add_new_owner(address account) private {
        if (!_isowner[account]) {
            _isowner[account] = true;
            SFT_owners.push(account);
        }
    }

    function _setURI(string memory newuri) internal virtual override{
        _uri = newuri;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        require(id>0 && id<=_tokenIdCounter.current(),"The requested ID does not exist");
        return string(abi.encodePacked(_uri, Strings.toString(id),'.json'));
    }         

    function mint(address buyer, uint256 amount, uint256 status) public onlyOwner()
    {
        _tokenIdCounter.increment();
        _mint(buyer, _tokenIdCounter.current(), amount, "");
        for (uint i=0; i<amount; i++) {
        nft_list[_tokenIdCounter.current()][buyer].push(status); 
        }
        add_new_owner(buyer);
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public override {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()),"ERC1155: caller is not owner nor approved");
        _safeTransferFrom(from, to, id, amount, data);
        for (uint i=0; i<amount;i++) {
            nft_list[id][to].push(nft_list[id][from][nft_list[id][from].length-1]);
            nft_list[id][from].pop();
        }
        add_new_owner(to);
    }

    function set_nft_status (uint256 SFT_Id, uint128 status, uint256 NFT_Id, address sft_owner) public onlyOwner() {
        require(nft_list[SFT_Id][sft_owner].length-1 >= NFT_Id, "ARRAY_NFT: print query for nonexistent token");
        nft_list[SFT_Id][sft_owner][NFT_Id] = status;      
        emit NFT_Status_Changed(SFT_Id, NFT_Id, status);
    }

    function get_nft_status (uint256 SFT_Id, uint256 NFT_Id, address sft_owner) public view returns(uint256) {
        require(nft_list[SFT_Id][sft_owner].length-1 >= NFT_Id, "ARRAY_NFT: print query for nonexistent token");
        return nft_list[SFT_Id][sft_owner][NFT_Id];
    }

    function get_sft_balance (uint256 SFT_Id) public view returns(uint256, address[] memory) {
        uint owner_count = 0;
        address[] memory i_address  = new address[](10);
        for (uint i=0; i<SFT_owners.length;i++) {
            for (uint j=1; j<_tokenIdCounter.current();j++) {
                if (balanceOf(SFT_owners[i], SFT_Id)>0) {
                    i_address[owner_count] = SFT_owners[i];
                    owner_count +=1;
                    break;
                }
            }    
        }
        address[] memory List_address = new address[](owner_count);
        for (uint i=0; i<owner_count;i++) {
            List_address[i] = i_address[i];
        }
        return (owner_count, List_address);
    }

    function request_print (uint256 SFT_Id, uint256 NFT_Id, address sft_owner) public {
        require(nft_list[SFT_Id][sft_owner].length-1 >= NFT_Id, "ARRAY_NFT: print query for nonexistent token");
        require(nft_list[SFT_Id][sft_owner][NFT_Id] % 10 == 1, "ARRAY_NFT: Any print is not available for this NFT");
        require(nft_list[SFT_Id][sft_owner][NFT_Id] % 100 / 10 != 1, "ARRAY_NFT: Print request for this NFT is already pending");
        require(nft_list[SFT_Id][sft_owner][NFT_Id] % 1000 /100 == 0, "ARRAY_NFT: This NFT has been already printed");
        require(sft_owner == msg.sender, "ARRAY_NFT: Only the owner of the NFT can request a print");
        nft_list[SFT_Id][sft_owner][NFT_Id] = 11;
    }
 
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function contractURI() public view returns (string memory) {
        return contract_uri;
    }

    function set_contractURI(string memory _contract_uri) public onlyOwner(){
        contract_uri = _contract_uri;
    }
}