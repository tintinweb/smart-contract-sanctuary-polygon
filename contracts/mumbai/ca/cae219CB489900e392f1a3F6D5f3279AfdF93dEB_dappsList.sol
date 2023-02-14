/**
 *Submitted for verification at polygonscan.com on 2023-02-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract dappsList {

    address owner;

	constructor() {
		owner = msg.sender;
	}

    struct Dapps {
        uint id;
        string name;
        string icon;
        uint status;
        string domain;
        string about;
    }
    mapping(uint => Dapps) Dapp;
    mapping(string => Dapps) Search;
    uint countDapps = 0;

	modifier ownerOn() {
		require(
            msg.sender==owner,
            "Only Owners"
        );
		_;
	}

    event postDapp (
        uint _id,
        string _name,
        string _icon,
        uint _status,
        string _domain,
        string _about
    );

    event updateDapp (
        uint _id,
        string _name,
        string _icon,
        uint _status,
        string _domain,
        string _about
    );

    event deleteDapp (
        uint _id,
        string _name,
        string _icon,
        uint _status,
        string _domain,
        string _about
    );

    function lastDappsId()
        view public returns(uint)
    {
        return countDapps;
    }

    function post(
        string memory name,
        string memory icon,
        uint status,
        string memory domain,
        string memory about
        )
        public ownerOn
    {
        countDapps ++;
        Dapp[countDapps] = Dapps(
            countDapps,
            name,
            icon,
            status,
            domain,
            about
        );
        Search[name] = Dapps(
            countDapps,
            name,
            icon,
            status,
            domain,
            about
        );
        emit postDapp (
            countDapps,
            name,
            icon,
            status,
            domain,
            about
        );
    }

    function search(string memory name_)
        view
        public
        returns(Dapps memory)
    {
        return Search[name_];
    }

    function getId(uint id_)
        view
        public
        returns(Dapps memory)
    {
        return Dapp[id_];
    }

    function getIdBatch(uint[] memory ids_)
        view
        public
        returns(Dapps[] memory)
    {
        Dapps[] memory dappsIds =
            new Dapps[](ids_.length);

        for (uint i = 0; i < ids_.length; ++i)
        {
            dappsIds[i] = getId(ids_[i]);
        }
        return dappsIds;
    }

    function update(
        uint id,
        string memory name,
        string memory icon,
        uint status,
        string memory domain,
        string memory about
    )
        public ownerOn
    {
        emit updateDapp (
            Dapp[id].id,
            Dapp[id].name,
            Dapp[id].icon,
            Dapp[id].status,
            Dapp[id].domain,
            Dapp[id].about
        );

        Dapp[id] = Dapps(
            Dapp[id].id,
            name,
            icon,
            status,
            domain,
            about
        );

        Search[Dapp[id].name] = Dapps(
            Dapp[id].id,
            name,
            icon,
            status,
            domain,
            about
        );

        emit updateDapp (
            Dapp[id].id,
            name,
            icon,
            status,
            domain,
            about
        );
    }

    function remove(uint id)
        public ownerOn
    {
        emit deleteDapp (
            Dapp[id].id,
            Dapp[id].name,
            Dapp[id].icon,
            Dapp[id].status,
            Dapp[id].domain,
            Dapp[id].about
        );

        delete Search[Dapp[id].name];
        delete Dapp[id];

        emit deleteDapp (
            Dapp[id].id,
            Dapp[id].name,
            Dapp[id].icon,
            Dapp[id].status,
            Dapp[id].domain,
            Dapp[id].about
        );
    }
}