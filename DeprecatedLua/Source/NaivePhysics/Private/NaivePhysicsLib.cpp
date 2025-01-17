// Fill out your copyright notice in the Description page of Project Settings.

#include "NaivePhysics.h"
#include "NaivePhysicsLib.h"


UMaterialInterface* UNaivePhysicsLib::GetMaterialFromName(const FString& Name)
{
    FString Prefix;
    FString Suffix;
    if(! Name.Split(FString(TEXT("/")), &Prefix, &Suffix, ESearchCase::IgnoreCase, ESearchDir::FromEnd))
    {
        Suffix = Name;
    }

    FString Path = FString(TEXT("Material'/Game/Materials/"))
        + Name + FString(TEXT(".")) + Suffix + FString(TEXT("'"));

    return LoadObject<UMaterialInterface>(nullptr, Path.GetCharArray().GetData());
}


UStaticMesh* UNaivePhysicsLib::GetStaticMeshFromName(const FString& Name)
{
    FString Path = FString(TEXT("StaticMesh'/Game/Meshes/"))
        + Name + FString(TEXT(".")) + Name + FString(TEXT("'"));

    return LoadObject<UStaticMesh>(nullptr, Path.GetCharArray().GetData());
}


UPhysicalMaterial* UNaivePhysicsLib::GetPhysicalMaterial(const float& Friction, const float& Restitution)
{
    UPhysicalMaterial* PhysicalMaterial = NewObject<UPhysicalMaterial>();
    PhysicalMaterial->Friction = Friction;
    PhysicalMaterial->Restitution = Restitution;
    PhysicalMaterial->UpdatePhysXMaterial();
    return PhysicalMaterial;
}
