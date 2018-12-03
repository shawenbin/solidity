pragma solidity ^0.5.0;
contract Dapp1 {
    enum teamRule { dictatorship, democratic, originator }  // maximum amount, subtotal everyone, who creat team
    enum countryRegion { China, Japan, UN }
    gameConfig public config;
    team[] public teams;
    mapping(address => memberInfo) public addr2member;
    struct gameConfig {
        address developer;
        uint8 currertRound;     // max 256, the starting point is 1
        uint16 currertGame;     // max 16777216
        uint88[2] teamCharge;   // cost of building a team in Gwei, fibonacci number, [last, current]
        uint dateNode;          // defint endTime
    }
    struct team {
        string name;
        countryRegion comeFrom;
        teamRule rule;
        uint8[2] lifeCycle; // [first, last] round
        uint8 attackIndex;  // team's index in arrary
        uint88 amount;      // max 309,485,010 eth
        address payable[] members;
    }
    struct memberInfo {
        string message;
        uint8 attackIndex;  // max 256
        join[] joins;
        uint88 balance;
    }
    struct join {
        uint8 teamIndex;
        uint88 amount;
    }
    constructor() public {
        config = gameConfig({developer:msg.sender, currertGame:0, currertRound:1, teamCharge:[uint88(1000000000),2000000000], dateNode:now});
        newGame();
    }
    function newGame() private {
        config.teamCharge = [1000000000,2000000000];
        config.currertGame ++;
        config.currertRound = 1;
        teams.length = 0;
        setupTeam("United Nations Peacekeeping Forces", countryRegion.UN, teamRule.democratic, 1, 0);   // Automatically build the first team
    }
    function newTeam(string memory name, countryRegion comeFrom, teamRule rule, uint8 attackIndex, string memory message) public payable {
        uint88 amount = uint88(msg.value) - config.teamCharge[1];
        require(amount > 0, "The amount is not enough to build up a team.");
        require(attackIndex <= teams.length, "The direction of attack is incorrect.");
        addr2member[config.developer].balance += config.teamCharge[1]; // team building cost transfer to developer account
        setupTeam(name, comeFrom, rule, attackIndex, amount);
        teams[teams.length-1].members.push(msg.sender);
        addr2member[msg.sender].joins.push(join({teamIndex:uint8(teams.length-1), amount:amount}));
        }
    function setupTeam(string memory name, countryRegion comeFrom, teamRule rule, uint8 attackIndex, uint88 amount) private {
        teams.length++;
        (teams[teams.length-1].name, teams[teams.length-1].comeFrom, teams[teams.length-1].rule,           teams[teams.length-1].lifeCycle, teams[teams.length-1].attackIndex, teams[teams.length-1].amount)
        =(                     name,                       comeFrom,                       rule, [config.currertRound,config.currertRound],                       attackIndex,                       amount);
        config.teamCharge = [config.teamCharge[1], config.teamCharge[0] + config.teamCharge[1]];    // calculate next fibonacci number
    }
    function joinTeam(uint8 teamIndex, uint8 attackIndex, string memory message) public payable {
        require(msg.value > 0, "Your amount is empty.");
        require(teams[teamIndex].lifeCycle[1] == config.currertRound, "The team is not in currertRound.");
        stateCheck();
        uint88 amount = uint88(msg.value);
        if(bytes(message).length > 0)
            addr2member[msg.sender].message = message;
        teams[teamIndex].amount += amount;
        uint8 i = 0;
        for(; i < addr2member[msg.sender].joins.length; i++) {
            if(addr2member[msg.sender].joins[i].teamIndex == teamIndex) {   // has joined before
                addr2member[msg.sender].joins[i].amount += amount;
                break;
            }
        }
        if(i == addr2member[msg.sender].joins.length) {                     // first time to join
            teams[teamIndex].members.push(msg.sender);
            addr2member[msg.sender].joins.push(join({teamIndex:teamIndex, amount:amount}));
        }
        attackTeam(attackIndex);
    }
    function attackTeam(uint8 attackIndex) public {
        for(uint8 i = 0; i < addr2member[msg.sender].joins.length; i++)
            sumAttack(addr2member[msg.sender].joins[i].teamIndex);
        if(addr2member[msg.sender].attackIndex != attackIndex)
            addr2member[msg.sender].attackIndex = attackIndex;
    }
    function sumAttack(uint8 index) private {
        uint88 maxAmount = 0;
        uint8 attackIndex;
        if(teams[index].rule == teamRule.dictatorship) {    // maximum amount is leader
            for(uint32 i = 0; i < teams[index].members.length; i++) {
                for(uint8 j = 0; j < addr2member[teams[index].members[i]].joins.length; j++) {
                    if(addr2member[teams[index].members[i]].joins[j].teamIndex == index) {
                        if(addr2member[teams[index].members[i]].joins[j].amount >= maxAmount)
                            (maxAmount, attackIndex) = (addr2member[teams[index].members[i]].joins[j].amount, addr2member[teams[index].members[i]].attackIndex);
                        break;
                    }
                }
            }
            teams[index].attackIndex = attackIndex;
        }
        else if(teams[index].rule == teamRule.democratic) { // subtotal everyone
            uint88[] memory totalAttacks = new uint88[](teams.length+1);
            for(uint32 i = 0; i < teams[index].members.length; i++) {
                for(uint8 j = 0; j < addr2member[teams[index].members[i]].joins.length; j++) {
                    if(addr2member[teams[index].members[i]].joins[j].teamIndex == index) {
                        totalAttacks[addr2member[teams[index].members[i]].attackIndex] += addr2member[teams[index].members[i]].joins[j].amount;
                        if(totalAttacks[addr2member[teams[index].members[i]].attackIndex] > maxAmount)
                            (maxAmount, attackIndex) = (totalAttacks[addr2member[teams[index].members[i]].attackIndex], addr2member[teams[index].members[i]].attackIndex);
                        break;
                    }
                }
            }
            teams[index].attackIndex = attackIndex;
        }
        else if(teams[index].rule == teamRule.originator) { // the first member is leader
        
        }
    }
    function stateCheck() public {
        if(now >= config.dateNode + 1 days) {
            if(teams.length > 2) {  // goto next round
                uint8 i;
                uint8 eliminateIndex;   // eliminate Team's index number in teams arrary
                uint88 maxInjury;       // max injury
                uint88 denominator;     // total Gwei in this round
                uint88[] memory injury = new uint88[](teams.length);
                for(i = 0; i < teams.length; i++) {
                    if(teams[i].lifeCycle[1] == config.currertRound) {
                        denominator += teams[i].amount;
                        if(teams[teams[i].attackIndex].lifeCycle[1] == config.currertRound) {
                            injury[teams[i].attackIndex] += teams[i].amount;
                            if(injury[teams[i].attackIndex] > maxInjury)
                                (eliminateIndex, maxInjury) = (teams[i].attackIndex, injury[teams[i].attackIndex]);
                        }
                    }
                }
                denominator -= teams[eliminateIndex].amount;
                uint88 numerator = teams[eliminateIndex].amount * 32 / 33;  // 3 percents developer fee
                addr2member[config.developer].balance += teams[eliminateIndex].amount - numerator;
                for(i = 0; i < teams.length; i++) {     // promote
                    if(teams[i].lifeCycle[1] == config.currertRound && i != eliminateIndex) {
                        teams[i].lifeCycle[1]++;
                        for(uint16 j = 0; j < teams[i].members.length; j++)
                            addr2member[teams[i].members[j]].balance += 1 * numerator / denominator;
                    }
                }
                config.dateNode += 1 days;
                config.currertRound++;
            }
            else {                  // goto next game
                newGame();
            }
        }
    }
    function drawGwei(address payable target, uint88 amount) public payable {
        require(addr2member[msg.sender].balance >= amount , "Balance is not enough.");
        stateCheck();
        addr2member[msg.sender].balance -= amount;
        target.transfer(amount);
    }
}
