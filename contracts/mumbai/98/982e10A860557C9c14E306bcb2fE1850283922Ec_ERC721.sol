// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0;

 import "./IERC721.sol"; 
  
    contract ERC721 is IERC721
    {

        string private _name;
        string private _symbol;
        address private _owner;

        uint internal mintCounter;

        // mapping

        mapping ( uint256 => address ) internal _Owners ;
        mapping ( address => uint256 ) private _balances ;
        mapping ( uint256 => address ) private _tokenApprovals ;
        mapping ( uint256 => string ) internal _tokenURIs ;
        mapping ( address => mapping ( address => bool )) private _opretorApprovals;


        constructor (string memory name_, string memory symbol_) 
        {
            _name = name_;
            _symbol = symbol_;
        }
        // main function 

        function name () public view returns (string memory) {

            return _name;
        }

        function symbol () public view returns (string memory) {

            return _symbol;
        }

        function baseURI () public pure returns (string memory) {

            return "" ;
        }

        function tokenURI (uint256 tokenId) public view returns (string memory) {
            return _tokenURIs[tokenId] ;
        } 

        modifier onlyOwner () {
            require (msg.sender == _owner);
            _;
        }

        function setTokenURI (uint256 tokenId, string memory tokenURI_) public onlyOwner {
            _tokenURIs[tokenId] = tokenURI_;
        }


        function supportInterface(bytes4 interfaceId) public view override returns (bool) {
            
            return interfaceId == interfaceId; 
        }

        function balanceOf (address owner) public view override returns (uint256) {
            require (owner != address(0), "INVALID: this address is zero");

            return _balances[owner];
        }

        function ownerOf (uint256 tokenId) public view override returns (address) {
            require (ERC721._Owners[tokenId] != address(0), "INVALID: address is zero" );

            return ERC721._Owners[tokenId];
        }

        function approve (address spender, uint256 tokenId) public override {
            require (ERC721._Owners[tokenId] != spender, "approval to current owner" );
            require (msg.sender == ERC721._Owners[tokenId] || isApprovalForAll(ERC721._Owners[tokenId] , msg.sender), "caller is not owner or approved all");

            _approve(spender, tokenId);
        }  

        function _approve (address to, uint256 tokenId) internal {

            _tokenApprovals [tokenId] = to;
            emit Approval(ERC721._Owners[tokenId] , to, tokenId);
        } 

        function isApprovalForAll (address owner, address spender) public view override returns (bool) {
            
            return _opretorApprovals[owner][spender];
        } 

        function getApproved (uint256 tokenId) public view override returns (address) {
            _requireMint(tokenId);

            return _tokenApprovals[tokenId];
        }

        function _requireMint (uint256 tokenId) internal view  {
            require(_exists(tokenId), "approve token is zero");
        }

        function _exists (uint256 tokenId) internal view returns (bool) {

            return ERC721._Owners[tokenId] != address(0) ;
        }

        function setApprovalForAll (address opretor, bool approved) public override {
            _setApprovalForAll(msg.sender, opretor, approved);
        }

        function _setApprovalForAll (address owner, address opretor, bool approved) internal {
            require(owner != opretor, "approve to caller");

            _opretorApprovals[owner][opretor] = approved;
            emit ApprovalForAll(owner, opretor, approved);
        }

        function transferFrom (address from, address to, uint256 tokenId) public override {
            require(_isApprovedOrOwner(msg.sender, tokenId), "caller is not token owner or approved");

            _transfer(from, to, tokenId);
        }

        function _isApprovedOrOwner (address spender, uint256 tokenId) internal view returns (bool) {
            
            return (spender == ERC721._Owners[tokenId] || isApprovalForAll(ERC721._Owners[tokenId], spender) || getApproved(tokenId) == spender);
        }

        function _transfer (address from, address to, uint256 tokenId) internal {
            require (ERC721._Owners[tokenId] == from, "transfer from incorrent owner");
            require (to != address(0), "transfre to address zero");

            delete _tokenApprovals[tokenId];

            _balances[from] -= 1;
            _balances[to] += 1;

            _Owners[tokenId] = to;
            emit Transfer(from, to, tokenId);
        }

        function safeTransferFrom (address from, address to, uint256 tokenId) public override {
            safeTransferFrom(from, to, tokenId, "");
        }

        function safeTransferFrom (address from, address to, uint256 tokenId, bytes memory data) public override {
            require(_isApprovedOrOwner(msg.sender, tokenId), "caller is not token Owner");
            _safeTransferFrom(from, to, tokenId, data);
        } 

        function _safeTransferFrom (address from, address to, uint256 tokenId, bytes memory data) internal {

            _transfer(from, to, tokenId);
        }

        function _mint (address to, uint256 tokenId) internal {
            require (to != address(0), "address is zero" );
            require (!_exists(tokenId), "this aleardy minted");

            _balances[to] += 1;
            _Owners[tokenId] = to;

            emit Transfer(address(0), to, tokenId);
        }

        function _safeMint(address to, uint256 tokenId) internal {
            _safeMint(to, tokenId, "");
        }

        function _safeMint (address to, uint256 tokenId, bytes memory data) internal {

            _mint(to, tokenId);
        }

        function mint (address to, string memory URI_ ) public onlyOwner {
            _safeMint(to, mintCounter);
            setTokenURI(mintCounter, URI_);

            mintCounter++ ;
        }
    }