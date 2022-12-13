/**
 *Submitted for verification at polygonscan.com on 2022-12-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract provenance {
     //unique id for the item;
    uint uID;
    uint Mid=1;
    uint Aid=1;
    uint Rid=1;


    //for the sake of simplicity I have used Mftr for Manufacturer :)
    struct Mftr
    {
        uint m_id;
        string m_part;
        uint month;
        uint year;
        string factory;
        string city;
        string state;
        string country;
        uint M_pincode;
        uint M_contact;
        string m_GSTN;
    }
    mapping (uint => Mftr) public M_info;

    struct Assembly
    {
        //parts is for the number of parts assembled 
        uint a_id;
        uint parts;
        uint month;
        uint year;
        string company;
        string city;
        string state;
        string country;
        uint A_pincode;
        uint A_contact;
        uint[] M_Ids;
        string a_GSTN;

    }
    mapping( uint => Assembly)public A_info;
   // this would work for both rid and aid, entering any of those 
   //user can get info of assmbler

   mapping(uint => bool) registered_a;
   mapping (address => bool) registered_asmblr;

    struct Retail
    {
        uint r_aid ;
        string outlet;
        string city;
        string state;
        string country;
        uint R_pincode;
        uint R_contact;
        string r_GSTN;

    }
    mapping (uint => Retail) public R_info;


    function M_details(string memory _part,
        uint _month,
        uint _year,
        string memory _factory,
        string memory _city,
        string memory _state,
        string memory _country,
        uint m_pincode,
        uint m_contact,
        string memory m_gstn) public 
        {
            Mftr storage new_mftr = M_info[Mid];
            new_mftr.m_id=Mid;
            new_mftr.month=_month;
            new_mftr.year=_year;
            new_mftr.m_part=_part;
            new_mftr.factory = _factory;
            new_mftr.city = _city;
            new_mftr.state = _state;
            new_mftr.country = _country;
            new_mftr.M_pincode = m_pincode;
            new_mftr.M_contact = m_contact;
            new_mftr.m_GSTN = m_gstn;
            Mid++;
          //  emit()
        }


    function A_details(uint _parts,
        uint _month,
        uint _year,
        string memory _company,
        string memory _city,
        string memory _state,
        string memory _country,
        uint a_pincode,
        uint a_contact,
        string memory a_gstn) public 
        {
            Assembly storage new_asmbly = A_info[Aid];
            new_asmbly.a_id=Aid;
            new_asmbly.parts=_parts;
            new_asmbly.month=_month;
            new_asmbly.year=_year;
            new_asmbly.company = _company;
            new_asmbly.city = _city;
            new_asmbly.state = _state;
            new_asmbly.country = _country;
            new_asmbly.A_pincode = a_pincode;
            new_asmbly.A_contact = a_contact;
            new_asmbly.a_GSTN = a_gstn;
            //uint[] memory m_parts = new uint[](_parts);
            registered_a[Aid]=true;
            registered_asmblr[msg.sender]=true;
            Aid++;
          //  emit()
        }

    mapping (uint => uint[]) try_arr;
    mapping (uint => bool) trialID;
        //assuming the three main parts user might need infor for,
        //for more parts we can update this anytime and it will add onto the corresponding array
    function A_M_infos(uint _a_id, uint mid1,uint mid2,uint mid3) public returns(uint[] memory){
            require(try_arr[_a_id].length<A_info[_a_id].parts);
            if(trialID[_a_id]=true){
                try_arr[_a_id].push(mid1);
            }
            else {
            try_arr[_a_id].push(mid1);
            try_arr[_a_id].push(mid2);
            try_arr[_a_id].push(mid3);
            }
            trialID[_a_id]=true;
            return try_arr[_a_id];
        }

        //for rid to assembler id
     // mapping(uint => uint)

    function R_details(uint a_id,
        string memory _outlet,
        string memory _city,
        string memory _state,
        string memory _country,
        uint r_pincode,
        uint r_contact,
        string memory r_gstn) public 
        {
            require(registered_a[a_id]==true,"assembler id of item is invalid");
            Retail storage new_retail = R_info[Rid];
            new_retail.r_aid=a_id;
            new_retail.outlet = _outlet;
            new_retail.city = _city;
            new_retail.state = _state;
            new_retail.country = _country;
            new_retail.R_pincode = r_pincode;
            new_retail.R_contact = r_contact;
            new_retail.r_GSTN = r_gstn;
            Rid++;
          //  emit()
        }

    //to 
    mapping(uint => Model) public Md_info;
    struct Model{
        uint uid_aid;
        string model_name;
        uint weight;
        uint cost;
        uint a_year;
    }

    modifier OnlyAssembler{
        require(registered_asmblr[msg.sender]==true,"you need to be assembler to add details");
        _;
    }

    function model_details(uint _id,string memory _name, uint _weight, uint _cost) public OnlyAssembler {
        Model storage newMdl = Md_info[_id];
        newMdl.uid_aid=_id;
        newMdl.model_name=_name;
        newMdl.weight=_weight;
        newMdl.cost=_cost;
        newMdl.a_year=A_info[_id].year;
    }


    //shipment details
    struct shipment{
        uint id;
        string from;
        string to;
        string cargo;
        uint month;
        uint year;
    }

    mapping(uint => shipment) public S_info;

    function Mshipment(uint _id, string memory _from, string memory _to, string memory _cargo, uint _month, uint _year) public
    {
        shipment storage newship = S_info[_id];
        newship.id=_id;
        newship.from=_from;
        newship.to=_to;
        newship.cargo=_cargo;
        newship.month=_month;
        newship.year=_year;

    }

}