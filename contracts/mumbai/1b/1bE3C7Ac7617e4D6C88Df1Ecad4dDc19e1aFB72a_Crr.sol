/**
 *Submitted for verification at polygonscan.com on 2023-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Crr {
struct gh
{
    bool alive;
    bool group;
    uint naghsh;
    uint vot;
    uint sab;
    uint aydi;
}
gh j;
 mapping (string => gh) yy;
 struct ethe{
uint z;
 }
 ethe rts;
 struct maf{
uint a;
 }
 maf maff;
  struct mafs{
uint a;
 }
 mafs shah;
  constructor(uint r) {
    rts.z = r;
     
 }
 modifier only (uint pas)
 {
require(pas == rts.z, "you are not ravi");
_;
 }
    uint rst;
    string [] jj;
    mapping (string => bool) dgd;
    mapping (string => bool) dgdd;
    mapping (string => uint) dgde;
    mapping (string => uint) dgude;
    mapping (uint => uint) ggk;
    struct ty {
        uint q;
    }
    ty sk;

    struct uj
    {
        uint x;
    }
    uj ju;
    function start_vot(uint pas) public only(pas)
    {
        ju.x = (block.timestamp + 60);
    }
    modifier time()
    {
        require(block.timestamp < ju.x);
        _;
    }
    mapping (uint => uint)cat;
    mapping (uint => bool) xfdx;
    function sapt_nam(uint naghsh, bool group, string memory name, uint pas, uint ravipas) public only(ravipas) {bool io = true;
    rst++;
        yy[name] = gh(io, group, naghsh, 0, 0, rst);
        dgd[name] = io;
        dgdd[name] = group;
        xfdx[rst] = group;
        dgde[name] = naghsh;
        dgude[name] = rst;
        jj.push(name);
        ji[name] = 0;
        ggk[rst] = 0;
        dt[name] = rst;
        ff[rst] = 0;
        rrt[pas] = true;
        sk.q = rst;
        gy[name] = true;
        srt[pas] = naghsh;
        ewr[pas] = rst;
        cat[rst] = pas;
        fff[rst] = name;
        deead[rst] = name;
        rst = hffc.a;
        if (group == false)
        {
            shah.a++;
        }
        else{
            maff.a++;
        }
    }
    modifier tyu(uint a)
    {
        require(srt[a] == 1, "you are not mafia");
_;
    }
        modifier tcyu(uint a)
    {
        require(srt[a] == 2, "you are not doktor");
_;
    }
    
        modifier txyu(uint a)
    {
        require(srt[a] == 3, "you are not karagah");
_;
    }
    

    modifier live(uint a)
    {uint d;
       d = ewr[a];
       require(rrt[d] == true, "you are did");
       _;
    }
    function see_naghsh(uint ur) public pure  returns(string memory) {
        if (ur == 1)
        {
            return "mafia";
        }
        else if (ur == 2)
        {
            return "doktor";
        }
        else if (ur == 3)
        {
            return "karagah";
        }
        else if (ur == 4)
        {
            return "person";
        }
        else
        {
            return "the number is false"; 
        }
    }
    function see_names() public view returns(string [] memory)
    {return jj;
}

mapping (string => uint) ji;
mapping (string => uint) dt;
mapping (uint => uint) ff;
mapping (string => bool) gy;
mapping (uint => bool) rrt;
mapping (uint => uint) srt;
mapping (uint => uint) ewr;
mapping (string => bool) rrk;
mapping (uint => string) fff;
mapping (uint => mapping(string => bool)) ok;

    modifier too (uint n)
    {
        require(rrt[n] == true, "you can do this");
        _;
    }
    struct ffh
    {
        uint a;
    }
    ffh hff;
        struct ffhc
    {
        uint a;
    }
    ffh hffc;
    struct ro
    {   
        uint mafia;
        uint shahrond;
    }
    struct dft
    {
        bool a;
    }
    dft cdg;
        struct dftt
    {
        bool a;
    }
    dft cdgg;
    function first_vot(uint ravipas, bool p)public only(ravipas)
    {
        cdg.a = p;
    }
        function second_vot(uint ravipas, bool p)public only(ravipas)
    {
        cdgg.a = p;
    }
    mapping(uint => string) deead;
    mapping (string => bool) tgbg;
    function vot(string memory uu, uint pas) public too(pas) live(pas) time 
    {require(ok[pas] [uu] == false, "you can vote to this person just one time");
    uint b = dgude[uu];
    hff.a = b;
     uint tg;
    tg = ji[uu];
    tg++;
    ji[uu] = tg;
    ggk[b] = tg;
    ok[pas] [uu] == true;
    }
    function show(uint pas) public only(pas)
    {string memory ssrt;
    for (uint y;hffc.a >= y; )
    {y++;
        if (ggk[y] >= (sk.q / 2))
        {
          ssrt = fff[y];
          tgbg[ssrt] = true;
          hju.push(ssrt);
        }
 }
    }

    string [] hju;
    function show_motaham (uint pas) public too(pas) view returns(string [] memory)
    {
        return hju;
    }
    function vot2(string memory uu, uint pas) public too(pas) live(pas) time
    {require(ok[pas] [uu] == false, "you can vote to this person just one time");
    uint qwe;
    uint fftr;
    qwe = dt[uu];
    fftr = cat[qwe];
    require(rrt[fftr] == true, "you can't vote to this person");
    require(tgbg[uu] == true, "you cant vot to the person");
    uint b = dgude[uu];
     uint tg;
    tg = ji[uu];
    tg++;
    ji[uu] = tg;
    ggk[b] = tg;
    ok[pas] [uu] == true;
    }
     function show2(uint pas) public only(pas) returns(string memory)
    {uint fftr;
    uint yvt;
    for (uint y;hffc.a >= y; )
    {y++;
    uint r;
    while (y == hffc.a)
    {
        r++;
    }
    if (ggk[r] < ggk[y] && ggk[y] >= (sk.q / 2))
    {
        if (yvt == y)
        {   yvt = 100;
            return "same";
        }
        else if(yvt < y)
        {
            yvt = y;
        }
        else if(yvt > y)
        {}
        else 
        {   yvt = 100;
            return "no kill";
        }
    }
    }
    for (uint t;20 > t; t++)
    {string memory tvy;
    tvy = hju[t];
    tgbg[tvy] = false;
    
    }
    fftr = cat[yvt];
    rrt[fftr] = false;
    delete hju;
    zzz.pi = yvt;
    if (ggk[yvt] >= (sk.q / 2))
    {
        if (xfdx[yvt] == false)
        {
            shah.a--;
        }
        else if (xfdx[yvt] == true)
        {
            maff.a--;
        }
    }
    }
        struct llhh
    {
        uint pi;
    }
    llh zzz;
    struct llh
    {
        uint pi;
    }
    llh zz;
        struct llj
    {
        uint pi;
    }
    llj xx;
        struct llk
    {
        uint pi;
    }
    llk cc;
    function start_night(uint pas) public only(pas)
    {zz.pi = (block.timestamp+20);
    xx.pi = (block.timestamp+40);
    cc.pi = (block.timestamp+60);
    uze.p = true;
}
function start_doktor(uint pasravi) public only(pasravi)
{
    uzee.p = true;
}
function start_karagah(uint pasravi) public only(pasravi)
{
    uzre.p = true;
}
struct rtey
{
    uint miu;
}
rtey dfth;

    struct byj
    {
        uint aewe;
    }
    byj cfrt;
    struct sed 
    {
        bool p;
    }
    sed uze;
        struct sedw 
    {
        bool p;
    }
    sed uzee;
        struct sede 
    {
        bool p;
    }
    sed uzre;
    function mafia(string memory er, uint pas) public live(pas) tyu(pas) {uint qwe;
      uint fftr;
      require(uze.p == true, "it's not your turn");
      require(zz.pi >= block.timestamp, "it's not your turn");
      require(dgdd[er] != true, "this is mafia");
    qwe = dt[er];
    fftr = cat[qwe];
      require(rrt[fftr] == true, "the player was dead");
      rrt[fftr] = false;
    cfrt.aewe = qwe;
    zzz.pi = qwe;
    shah.a--;
    uze.p = false;
    }
    function doktor(string memory er, uint pas) public live(pas) tcyu(pas) {uint qwe;
    uint fftr;
        require(uzee.p == true, "it's not your turn");
        require(block.timestamp >= zz.pi, "it's not your turn");
        require(xx.pi >= block.timestamp, "it's not your turn");
    qwe = dt[er];
    fftr = cat[qwe];
    require(qwe == cfrt.aewe, "your choice is not corect");
    rrt[fftr] = true;
    shah.a++;
    zzz.pi = 100;
    uzee.p = false;
    }
    function karagah(string memory er, uint pas) public live(pas) txyu(pas) returns(bool) {uint qwe;
    uint fftr;
    qwe = dt[er];
    fftr = cat[qwe];
    require(uzre.p == true, "it's not your turn");
    require(block.timestamp >= xx.pi, "it's not your turn");
    require(cc.pi >= block.timestamp, "it's not your turn");
    uzre.p = false;
    return dgdd[er];
    }
    function vaziat(uint ravipas)public only(ravipas) view returns(string memory)
    {
        if (zzz.pi == 100)
        {
            return "no kill";
        }
        else if (zzz.pi < 99)
        {
            return deead[zzz.pi];
        }
        else if (shah.a == maff.a)
        {
            return "mafia is win";
        }
        else if (maff.a == 0)
        {
            return "shahroand is win";
        }
    }
}