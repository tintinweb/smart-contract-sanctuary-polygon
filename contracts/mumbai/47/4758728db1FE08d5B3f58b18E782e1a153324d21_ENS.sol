/**
 *Submitted for verification at polygonscan.com on 2023-03-31
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract ENS {
    mapping(address => string) public userToDomain;
    mapping(string => address) public domainToUser;

    mapping(string => bool) public isExists;
    mapping(address => bool) public hasDomain;

    uint public domainCounter = 1;

    event DomainCreated(
        address indexed creator,
        string domainName,
        uint indexed domainId,
        uint time
    );
    event DomainDestroyed(
        address indexed owner,
        string domainName,
        uint time
    );
    event DomainTransfered(
        address indexed from,
        address indexed to,
        string domainName,
        uint time
    );

    modifier isDomainExists(string calldata _domain) {
        require(
            isExists[_domain] == true,
            "Domain does not exists!"
        );
        _;
    }

    modifier onlyDomainOwner(string calldata _domain) {
        require(
            keccak256(bytes(userToDomain[msg.sender])) == keccak256(bytes(_domain)),
            "Only domain owner."
        );
        _;
    }

    modifier isDomainNotExists(string calldata _domain) {
        require(
            isExists[_domain] == false,
            "Domain exists!"
        );
        _;
    }

    modifier isRecepientDoesNotHaveDomain(address _recepient) {
        require(
            hasDomain[_recepient] == false,
            "Recepient currently has a domain!"
        );
        _;
    }

    function createDomain(string calldata _domain)
        external
        isRecepientDoesNotHaveDomain(msg.sender)
        isDomainNotExists(_domain)
    {
        require(
            bytes(_domain).length > 5,
            "Domain names must have at least 5 characters!"
        );

        userToDomain[msg.sender] = _domain;
        domainToUser[_domain] = msg.sender;
        hasDomain[msg.sender] = true;
        isExists[_domain] = true;
        
        emit DomainCreated(
            msg.sender,
            _domain,
            domainCounter,
            block.timestamp
        );

        domainCounter++;
    }

    function destroyDomain(string calldata _domain)
        external
        isDomainExists(_domain)
        onlyDomainOwner(_domain)
    {
        delete userToDomain[msg.sender];
        delete domainToUser[_domain];
        delete hasDomain[msg.sender];
        delete isExists[_domain];

        emit DomainDestroyed(
            msg.sender,
            _domain,
            block.timestamp
        );
    }

    function transferDomain(
        string calldata _domain,
        address _recepient
    )
        external
        isDomainExists(_domain)
        onlyDomainOwner(_domain)
        isRecepientDoesNotHaveDomain(_recepient)
    {
        require(_recepient != address(0), "Invalid recepient address!");

        delete hasDomain[msg.sender];

        userToDomain[_recepient] = _domain;
        domainToUser[_domain] = _recepient;
        hasDomain[_recepient] = true;

        emit DomainTransfered(
            msg.sender,
            _recepient,
            _domain,
            block.timestamp
        );
    }
}