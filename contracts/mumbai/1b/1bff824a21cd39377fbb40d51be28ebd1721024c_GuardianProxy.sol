/* SPDX-License-Identifier: MIT */
pragma solidity ^0.8.6;

import {ERC1056} from "./IERC1056.sol";

contract GuardianProxy {
    ERC1056 public erc1056Contract;
    address public didRegistry =
        address(0xdCa7EF03e98e0DC2B855bE647C39ABe984fcF21B);
    address public _owner;
    bytes32 defaultName =
        0x6469642f7075622f536563703235366b312f766572694b657900000000000000;
    uint256 defaultValidity = 31556952000;
    mapping(address => Organization) _organizations; //key:addressfor DidOrganizations-> (key:addressfor DidUser->Value: enabled/not enabled)
    mapping(address => mapping(address => uint256)) public _nonce; //Key Organization -> (Key SystemAccountAddress/Identity - Value: uint256))

    struct Organization {
        address guardian;
        mapping(address => bool) auths;
        bool exists;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Only Owner");
        _;
    }

    modifier onlyAuthOrGuardian(address organization) {
        require(
            _organizations[organization].auths[msg.sender] ||
                _organizations[organization].guardian == msg.sender,
            "Only Auth"
        );
        _;
    }

    constructor() {
        erc1056Contract = ERC1056(didRegistry);
        _owner = msg.sender;
    }

    function addOrganization(
        address organization,
        address guardian,
        address auth
    ) public onlyOwner {
        require(
            !_organizations[organization].exists,
            "already exists organization"
        );
        _organizations[organization].exists = true;
        _organizations[organization].guardian = guardian;
        _addAuth(organization, auth);
    }

    function addAuth(address organization, address auth)
        public
        onlyAuthOrGuardian(organization)
    {
        _addAuth(organization, auth);
    }

    function _addAuth(address organization, address auth) internal {
        require(
            !_organizations[organization].auths[auth] &&
                msg.sender != _organizations[organization].guardian,
            "invalid addAuth"
        );
        _organizations[organization].auths[auth] = true;
        erc1056Contract.setAttribute(
            organization,
            defaultName,
            abi.encodePacked(auth),
            defaultValidity
        );
    }

    function removeAuth(address organization, address auth)
        public
        onlyAuthOrGuardian(organization)
    {
        require(
            _organizations[organization].auths[auth] &&
                msg.sender != _organizations[organization].guardian,
            "invalid removeAuth"
        );
        _organizations[organization].auths[auth] = false;
        erc1056Contract.revokeAttribute(
            organization,
            defaultName,
            abi.encodePacked(auth)
        );
    }

    function setAssertionMethod(address organization, address identity) public {
        erc1056Contract.setAttribute(
            organization,
            defaultName,
            abi.encodePacked(identity),
            defaultValidity
        );
    }

    function setAssertionMethodSigned(
        address organization,
        address identity,
        address from,
        bytes memory sig,
        bytes memory friendlyHash
    ) public onlyOwner {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0),
                this,
                _nonce[organization][from],
                from,
                "setAssertionMethodSigned",
                organization,
                identity,
                friendlyHash
            )
        );
        address signer = checkSignature(
            from,
            sig,
            hash,
            organization
        );
        require(_organizations[organization].auths[signer], "Only Auth");
        erc1056Contract.setAttribute(
            organization,
            defaultName,
            abi.encodePacked(identity),
            defaultValidity
        );
    }

     function checkSignature(
         address from,
        bytes memory sig,
        bytes32 hash,
        address organization
    ) internal returns (address) {
        address signer = ecrecovery(hash, sig);
        require(signer == from, "signer <> from");
        _nonce[organization][from]++;
        return signer;
    }

    function ecrecovery(bytes32 hash, bytes memory sig)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65) {
            return address(0);
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        return ecrecover(hash, v, r, s);
    }
    //function addAuth(address organization, address auth) public onlyAuthOrGuardian(organization) {
    //onlyAuthOrGuardian(identity)
    //TODO: falta implementar el setAttributteSigned
    //TODO: falta implementar nonce
    //TODO: falta implementar revoque
}