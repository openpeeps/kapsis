# Yacli - Build delightful Command Line interfaces in seconds
# 
#   (c) 2023 George Lemon | MIT license
#       Made by Humans from OpenPeeps
#       https://github.com/openpeeps/yacli

import std/[macros, strutils, os]
import pkg/pkginfo

type
  DBType* = enum
    dbJSON, dbMsgPacked, dbLMDB, dbSQLite

  Database* = ref object
    dbType: DBType
    version: string

export DBType, Database

proc newDatabase(dbType: DBType = dbMsgPacked): Database

macro initMetaInfo(dbType: DBType) =
  result = newStmtList()
  result.add(
    newConstStmt(
      ident "currAppName",
      newCall(
        newDotExpr(
          newCall(ident "pkg"),
          ident "getName"
        )
      )
    ),
    nnkConstSection.newTree(
      # Generate absolute path for `cacheDirKlymene`
      # Example: /home/{user}/.cache/klymene
      nnkConstDef.newTree(
        ident "cacheDirKlymene",
        newEmptyNode(),
        nnkInfix.newTree(
          ident "/",
          newCall(
            ident "getCacheDir"
          ),
          newLit "klymene"
        )
      ),
      # Generate absolute path for `cacheDirApp`
      # Example: /home/{user}/.cache/klymene/{app}
      nnkConstDef.newTree(
        ident "cacheDirApp",
        newEmptyNode(),
        nnkInfix.newTree(
          ident "/",
          ident "cacheDirKlymene",
          newCall(
            newDotExpr(
              newCall(ident "pkg"),
              ident "getName"
            )
          )
        )
      ),
      nnkConstDef.newTree(
        ident "cacheDatabasePath",
        newEmptyNode(),
        nnkInfix.newTree(
          ident "/",
          ident "cacheDirApp",
          newLit "db"
        )
      ),
      nnkConstDef.newTree(
        ident "appVersion",
        newEmptyNode(),
        nnkPrefix.newTree(
          ident "$",
          nnkPar.newTree(
            newDotExpr(
              newCall(ident "pkg"),
              ident "getVersion"
            )
          )
        )
      )
    )
  )


initMetaInfo(dbMsgPacked)

proc newDatabase(dbType: DBType = dbMsgPacked): Database =
  ## Creates a new flat file database
  result = Database(dbType: dbType, version: appVersion)

