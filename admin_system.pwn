/*
	Filterscript - Admin system
	Author: Bokenzi
	26/11/2020 - 14:50
*/

////
// - Includes
////

#include 	< a_samp >
#include 	< a_mysql >
#include 	< sscanf2 >
#include 	< Pawn.CMD >
#include 	< YSI_Coding\y_va >

////
// - Defines
////

#define 	Function%0(%1) 	forward%0(%1); public%0(%1)

#define 	d_admins 2552
#define 	d_acode  2553

////
// - Enum & variables
////

enum player_data {

	Admin,
	AdminCode

}
new PI[MAX_PLAYERS][player_data];

new MySQL:sql;

////
// - Commands
////

CMD:setadmin(arg, params[]) {

	if(IsPlayerAdmin(arg)) {

		new id, alevel, acode = random(800) + 113;

		if(sscanf(params, "ud", id, alevel)) 
			return SendClientMessage(arg, -1, "/setadmin [ID/Ime Igraca] [Admin Level]");

		if(!IsPlayerConnected(id)) 
			return false;

		if(alevel < 0 || alevel > 5) 
			return SendClientMessage(arg, -1, "Admin leveli ne mogu ici ispod 0 i iznad 5");

		new str[128];

		if(alevel == 0) {

			mysql_format(sql, str, sizeof str, "SELECT * FROM `admins` WHERE `admin_name` = '%e'", GetName(id));
			mysql_tquery(sql, str, "SQL_AdminRemove", "dd", arg, id);

		} else {

			mysql_format(sql, str, sizeof str, "SELECT * FROM `admins` WHERE `admin_name` = '%e'", GetName(id));
			mysql_tquery(sql, str, "SQL_AdminAdd", "dddd", arg, id, alevel, acode);

		}

	} else return SendClientMessage(arg, -1, "Niste prijavljeni kao rcon admin");

	return true;
}

CMD:changeacode(arg, params[]) {

	if(IsPlayerAdmin(arg)) {

		new id, acode;

		if(sscanf(params, "ud", id, acode))
			return SendClientMessage(arg, -1, "/changeacode [ID/Ime Admina] [Admin Kod]");

		if(!IsPlayerConnected(id))
			return false;

		new str[75];

		mysql_format(sql, str, sizeof str, "SELECT * FROM `admins` WHERE `admin_name` = '%e'", GetName(id));
		mysql_tquery(sql, str, "SQL_AdminCodeChange", "ddd", arg, id, acode);

	} else return SendClientMessage(arg, -1, "Niste prijavljeni kao rcon admin");

	return true;
}

CMD:admins(arg) {

	new str[85], list[1700];

	for(new i; i < MAX_PLAYERS; ++i) {

		if(IsPlayerConnected(i)) {

			if(PI[arg][Admin] >= 1) {

				format(str, sizeof str, "%d - %s\n", i+1, GetName(i));
				strcat(list, str);

			}

		}

	}

	if(!strlen(list))
		return SendClientMessage(arg, -1, "Trenutno nema aktivnih admina na serveru");

	ShowPlayerDialog(arg, d_admins, DIALOG_STYLE_LIST, "Admin list", list, "Ok", "");

	return true;
}

CMD:alladmins(arg) {

	mysql_tquery(sql, "SELECT * FROM `admins`", "SQL_ShowAdminDialog");

	return true;
}

////
// - Callbacks
////

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {

	if(dialogid == 2553) {

		if(!response) return Kick(playerid);
		else {

			if(strval(inputtext) != PI[playerid][AdminCode])
				return SendClientMessage(playerid, -1, "Pogresan admin kod, izbaceni ste sa servera"), SetTimerEx("KickTimer", 50, false, "d", playerid);

			SetSpawnInfo(playerid, 0, 26, 1958.33, 1343.12, 15.36, 269.15, 0, 0, 0, 0, 0, 0);
			SpawnPlayer(playerid);

		}

	}

	return true;
}

////
// - Functions
////

Function SQL_ShowAdminDialog(arg) {

	if(!cache_num_rows())
		return SendClientMessage(arg, -1, "U databazi nije pronadjen ni jedan admin");

	new str[85], aname[24], list[1700];

	for(new i; i < cache_num_rows(); ++i) {
		cache_get_value_name(i, "admin_name", aname, 24);
		format(str, sizeof str, "%s\n", aname);
		strcat(list, str);
	}

	ShowPlayerDialog(arg, d_admins, DIALOG_STYLE_LIST, "Lista svih admina", list, "U redu", "");

	return true;
}

Function SQL_AdminShield(arg) {

	if(!cache_num_rows()) {

		SetSpawnInfo(arg, 0, 26, 1958.33, 1343.12, 15.36, 269.15, 0, 0, 0, 0, 0, 0);
		SpawnPlayer(arg);

	}

	else {

		cache_get_value_name_int(0, "admin_code", PI[arg][AdminCode]);
		cache_get_value_name_int(0, "admin_level", PI[arg][Admin]);

		ShowPlayerDialog(arg, d_acode, DIALOG_STYLE_PASSWORD, "Admin zastita", "Na nasem serveru postoji dodatna zastita, a to je admin zastita\nUkucajte vas admin kod kako bih usli na server i koristili admin komande", "Unos", "X");

	}

	return true;
}

Function SQL_AdminCodeChange(arg, id, acode) {

	if(!cache_num_rows())
		return SendClientMessage(arg, -1, "Taj igrac nije admin na serveru");

	new str[128];

	mysql_format(sql, str, sizeof str, "UPDATE `admins` SET `admin_code` = '%d' WHERE `admin_name` = '%e'", acode, GetName(id));
	mysql_tquery(sql, str, "SQL_AdminChodeChanged", "ddd", arg, id, acode);

	return true;
}

Function SQL_AdminChodeChanged(arg, id, acode) {

	va_SendClientMessage(arg, -1, "Promijenili ste adminu %s kod", GetName(id));
	va_SendClientMessage(id, -1, "Admin %s vam je promjenio admin kod, vas novi je kod je: %d", GetName(arg), acode);

	return true;
}

Function SQL_AdminRemove(arg, id) {

	new str[128];

	if(!cache_num_rows())
		return SendClientMessage(arg, -1, "Taj igrac nije admin na serveru");

	mysql_format(sql, str, sizeof str, "DELETE FROM `admins` WHERE `admin_name` = '%e'", GetName(id));
	mysql_tquery(sql, str, "SQL_AdminRemoved", "dd", arg, id);

	return true;
}

Function SQL_AdminAdd(arg, id, alevel, acode) {

	new str[128];

	if(cache_num_rows() == 20)
		return SendClientMessage(arg, -1, "U admin team-u mogu biti najvise 20 admina");

	if(!cache_num_rows()) {

		mysql_format(sql, str, sizeof str, "INSERT INTO `admins` (`admin_name`, `admin_level`, `admin_code`) VALUES ('%e', '%d', '%d')", GetName(id), alevel, acode);
		mysql_tquery(sql, str, "SQL_AdminAdded", "dddd", arg, id, acode, alevel);

	}
	else {

		mysql_format(sql, str, sizeof str, "UPDATE `admins` SET `admin_level` = '%d', `admin_code` = '%d' WHERE `admin_name` = '%e'", alevel, acode, GetName(id));
		mysql_tquery(sql, str, "SQL_AdminAdded", "dddd", arg, id, acode, alevel);

	}

	return true;
}

Function SQL_AdminAdded(arg, id, acode, alevel) {

	va_SendClientMessage(arg, -1, "Postavili ste igracu %s admin poziciju", GetName(id));
	va_SendClientMessage(id, -1, "Admin %s vam je postavio admin poziciju, vas sigurnosni admin kod je: %d", GetName(arg), acode);

	PI[id][Admin] = alevel;
	PI[id][AdminCode] = acode;

	return true;
}

Function SQL_AdminRemoved(arg, id) {

	va_SendClientMessage(arg, -1, "Skinuli ste admin poziciju igracu %s", GetName(id));
	va_SendClientMessage(id, -1, "Admin %s vam je skinuo admin poziciju", GetName(arg));

	PI[id][Admin] = 0;

	return true;
}

////
// - Plain functions
////

GetName(arg) {

	new name[MAX_PLAYER_NAME+1];
	GetPlayerName(arg, name, sizeof name);

	return name;
}