/**
 *Submitted for verification at polygonscan.com on 2022-12-26
*/

// SPDX-License-Identifier: MIT 

    pragma solidity ^0.8.0; 

     interface IERC721 
     {
        event Transfer (address indexed from, address indexed to, uint256 tokenId) ;
        event Approval (address indexed from, address indexed to, uint256 tokenId) ;
        event ApprovalForAll (address indexed from, address indexed to, bool approve) ;

        function balanceOf (address owner) external view returns (uint256) ;
        function ownerOf (uint256 tokenId) external view returns (address) ;
        function safeTransferFrom (address from, address to, uint256 tokenId, bytes memory data) external ;
        function safeTransferFrom (address from, address to, uint256 tokenId) external ;
        function transfreFrom (address from, address to, uint256 tokenId) external ;
        function approve (address to, uint256 tokenId) external ;
        function setApprovalForAll (address opretor, bool approved) external ;
        function getApproved (uint256 tokenId) external view returns (address) ;
        function isApprovedForAll (address owner, address opretor) external view returns (bool) ;
        
     }

     interface IERC721Metadata 
     {

        function name() external view returns (string memory) ;
        function symbol() external view returns (string memory) ;
        function tokenURI(uint256 tokenId) external view returns (string memory) ;

     }

     contract Zeuse is IERC721, IERC721Metadata
     {
        string private _name;
        string private _symbol;

        uint256 public _mintCount;

        mapping (uint256 => address) _owners ;
        mapping (address => uint256) _balances ;
        mapping (uint256 => address) _tokenApprovals ;
        mapping (uint256 => string) _tokenURIs ;
        mapping (address => mapping (address => bool)) _opretorApprovals ;

        constructor (string memory name_, string memory symbol_){
            _name = name_;
            _symbol = symbol_;
        }

        function name() public view override returns (string memory) {
            return _name;
        }

        function symbol() public view override returns (string memory) {
            return _symbol;
        }

        function tokenURI (uint256 tokenId) public view override returns (string memory) {

            return _tokenURIs[tokenId] ;
        }

        function balanceOf (address owner) public view override returns (uint256) {
            require(owner != address(0) );
            
            return _balances[owner];
        }

        function ownerOf (uint256 tokenId) public view override returns (address) {
            require (Zeuse._owners[tokenId] != address(0) );

            return Zeuse._owners[tokenId];
        }

        function setURI (uint tokenId, string memory _URI) public {
            require(_exist(tokenId));
            _tokenURIs[tokenId] = _URI;
        }

        function approve (address to, uint256 tokenId) public override {
            require (to != address(0) );
            require (msg.sender == Zeuse._owners[tokenId] || isApprovedForAll(Zeuse._owners[tokenId], msg.sender)) ;

            _approve(to, tokenId);
        }

        function isApprovedForAll(address owner, address opretor) public view override returns (bool) {

            return _opretorApprovals[owner][opretor] ;
        }

        function _approve (address to, uint256 tokenId) internal {
            _tokenApprovals[tokenId] = to;

            emit Approval(Zeuse._owners[tokenId], to, tokenId);
        }

        function getApproved (uint256 tokenId) public view override returns (address) {
            _requireMint(tokenId) ;

           return _tokenApprovals[tokenId] ;
        }

        function _requireMint (uint256 tokenId) internal view {
            require(_exist(tokenId));
        }

        function _exist (uint256 tokenId) internal view returns (bool) {

            return Zeuse._owners[tokenId] != address(0) ;
        }

        function setApprovalForAll (address opretor, bool _approved) public override {

            _setApprovalForAll(msg.sender, opretor, _approved);
        }

        function _setApprovalForAll (address owner, address opretor, bool _approved  ) internal {
            require (owner != opretor) ;

            _opretorApprovals[owner][opretor] = _approved;
        }

        function transfreFrom (address from, address to, uint256 tokenId) public override {
            require(_isApprovedOrOwner(msg.sender, tokenId));

            _transfer(from, to, tokenId);
        }

        function _isApprovedOrOwner (address spender, uint256 tokenId) internal view returns (bool) {

            return (spender == Zeuse._owners[tokenId]) || (isApprovedForAll(Zeuse._owners[tokenId], spender)) || (getApproved(tokenId) == spender) ;
        } 
        
        function _transfer (address from, address to, uint256 tokenId) internal {
            require (from != address(0), "address is zero" );
            require (to != address(0), "address is zero" );

            delete _tokenApprovals[tokenId];

            _balances[from] -= 1;
            _balances[to] += 1;

            _tokenApprovals[tokenId] = to;
            emit Transfer(from, to, tokenId);
        }

        function safeTransferFrom (address from, address to, uint256 tokenId) public override {
            
            safeTransferFrom (from, to, tokenId, "");
        }

        function safeTransferFrom (address from, address to, uint256 tokenId, bytes memory data) public override {
            require (_isApprovedOrOwner(msg.sender, tokenId));
            
            _safeTransferFrom(from, to, tokenId, data) ;
        }

        function _safeTransferFrom (address from, address to, uint256 tokenId, bytes memory data) internal {
            
            _transfer(from, to, tokenId);
        }

        function _mint (address to, uint256 tokenId) internal {
            require(to != address(0),"this address is zero" );
            require(!_exist(tokenId), "the token id minted");

            unchecked {
                _balances[to] += 1;
            }

            _owners[tokenId] = to;
            emit Transfer(address(0), to, tokenId);
        }

        function _safeMint (address to, uint256 tokenId) internal {
            _safeMint(to, tokenId, "");
        }

        function _safeMint (address to, uint256 tokenId, bytes memory data) internal {
            _mint(to, tokenId) ;
        }

        function mint (address to, uint256 tokenId) public {
            _requireMint(tokenId);

            _safeMint(to, tokenId);
            _mintCount++;
        }

     }