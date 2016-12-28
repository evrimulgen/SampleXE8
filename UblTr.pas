unit UblTr;

interface

uses
  Contracts, Xml.XMLIntf, Xml.XMLDoc, System.SysUtils, System.TypInfo;

const
  PR_cbc = 'cbc';
  NS_cbc = 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2';
  PR_cac = 'cac';
  NS_cac = 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2';

procedure CreateUblTr(fatura: TFatura);
procedure ChangeNode(parent: IXMLNode; name, namespace, value: String);
procedure KalemEkle(node: IXMLNode; kalem: TKalem; BelgePB: String);
function CreateChildNode(node: IXMLNode; namespace, name: String): IXMLNode;
procedure AddChildNode(node: IXMLNode; namespace, name, value: String);
procedure MuhatapBilgileri(node: IXMLNode; muhatap: TMuhatap);

implementation

procedure CreateUblTr(fatura: TFatura);
var
  doc: IXMLDocument;
  parent: IXMLNode;

  faturatipi: IXMLNode;

  node: IXMLNode;
  new: IXMLNode;

  Uid: TGuid;
  ETTN: String;

  muhatap: TMuhatap;
  i: Integer;
begin
  doc := LoadXMLDocument('base.xml');
  doc.Options := doc.Options + [doNodeAutoIndent];
  parent := doc.DocumentElement;

  // ETTN
  CreateGuid(Uid);
  ETTN := GuidToString(Uid);
  ETTN := StringReplace(ETTN, '{', '', [rfReplaceAll]);
  ETTN := StringReplace(ETTN, '}', '', [rfReplaceAll]);
  ChangeNode(parent, 'UUID', NS_cbc, ETTN);
  // fatura no
  ChangeNode(parent, 'ID', NS_cbc, 'ISS2016000000001');

  // fatura senaryosu
  node := parent.ChildNodes.FindNode('ProfileID', NS_cbc);
  node.Text := GetEnumName(TypeInfo(TFaturaSenaryo), Ord(fatura.Senaryo));

  // fatura tipi
  faturatipi := parent.ChildNodes.FindNode('InvoiceTypeCode', NS_cbc);
  faturatipi.Text := GetEnumName(TypeInfo(TFaturaTipi), Ord(fatura.Tipi));

  // sat�c�
  // muhatap := TMuhatap.Create;
  // MuhatapBilgileri(parent.ChildNodes.FindNode('AccountingSupplierParty', NS_cac), muhatap);

  // m��teri
  muhatap := TMuhatap.Create;
  muhatap.WebURI := 'http://www.isisbilisim.com.tr';
  muhatap.VKNTCKN := '46603924300';
  muhatap.Unvan := 'ISIS Bili�im Teknolojileri';
  muhatap.Ilce := 'Ata�ehir';
  muhatap.Il := '�stanbul';
  muhatap.Ulke := 'T�rkiye';
  muhatap.UlkeKodu := 'TR';
  muhatap.VergiDairesi := '�lyasbey';
  MuhatapBilgileri(parent.ChildNodes.FindNode('AccountingCustomerParty',
    NS_cac), muhatap);

  // Fatura notu ekle
  new := doc.CreateElement(PR_cbc + ':Note', NS_cbc);
  new.Text := 'Fatura notu';
  new.Attributes['languageID'] := 'tr-TR';
  parent.ChildNodes.Insert(parent.ChildNodes.IndexOf(faturatipi) + 1, new);

  // Kalem ekle
  for i := 0 to fatura.Kalemler.Count - 1 do
    KalemEkle(parent, fatura.Kalemler[i], fatura.BelgePB);
  // Dosyaya kaydet
  doc.SaveToFile('sample.xml');
end;

procedure ChangeNode(parent: IXMLNode; name, namespace, value: String);
var
  node: IXMLNode;
begin
  node := parent.ChildNodes.FindNode(name, namespace);
  if node = nil then
    exit;
  if value = '' then
  begin
    parent.ChildNodes.Remove(node);
    exit;
  end;
  node.Text := value;
end;

procedure AddChildNode(node: IXMLNode; namespace, name, value: String);
var
  new: IXMLNode;
begin
  new := node.OwnerDocument.CreateElement(name, namespace);
  if value <> '' then
    new.Text := value;
  node.ChildNodes.Add(new);

end;

function CreateChildNode(node: IXMLNode; namespace, name: String): IXMLNode;
begin
  Result := node.OwnerDocument.CreateElement(name, namespace);
  node.ChildNodes.Add(Result);
end;

procedure MuhatapBilgileri(node: IXMLNode; muhatap: TMuhatap);
var
  new: IXMLNode;
  child: IXMLNode;
  i: Integer;
begin
  // party eleman�na git
  node := node.ChildNodes.First;
  // t�m alt elemanlar� temizle
  node.ChildNodes.Clear;

  // web adresi
  AddChildNode(node, NS_cbc, PR_cbc + ':WebsiteURI', muhatap.WebURI);
  // VKN/TCKN
  new := CreateChildNode(node, NS_cac, PR_cac + ':PartyIdentification');
  child := node.OwnerDocument.CreateElement(PR_cbc + ':ID', NS_cbc);
  child.Text := muhatap.VKNTCKN;
  if Length(muhatap.VKNTCKN) = 11 then
    child.Attributes['schemeID'] := 'TCKN'
  else if Length(muhatap.VKNTCKN) = 10 then
    child.Attributes['schemeID'] := 'VKN'
  else
    raise Exception.Create('VKNTCKN format� uygun de�il!');
  new.ChildNodes.Add(child);

  // T�zel �irket �nvan
  if Length(muhatap.VKNTCKN) = 10 then
  begin
    new := CreateChildNode(node, NS_cac, PR_cac + ':PartyName');
    AddChildNode(new, NS_cbc, PR_cbc + ':Name', muhatap.Unvan);
    child := node.OwnerDocument.CreateElement(PR_cbc + ':Name', NS_cbc);
  end;
  // Adres
  new := CreateChildNode(node, NS_cac, PR_cac + ':PostalAddress');
  AddChildNode(new, NS_cbc, PR_cbc + ':Room', '');
  AddChildNode(new, NS_cbc, PR_cbc + ':StreetName', '');
  AddChildNode(new, NS_cbc, PR_cbc + ':BuildingName', '');
  AddChildNode(new, NS_cbc, PR_cbc + ':BuildingNumber', '');
  AddChildNode(new, NS_cbc, PR_cbc + ':CitySubdivisionName', muhatap.Ilce);
  AddChildNode(new, NS_cbc, PR_cbc + ':CityName', muhatap.Il);
  AddChildNode(new, NS_cbc, PR_cbc + ':PostalZone', '');
  AddChildNode(new, NS_cbc, PR_cbc + ':Region', '');
  child := node.OwnerDocument.CreateElement(PR_cac + ':Country', NS_cac);
  new.ChildNodes.Add(child);
  AddChildNode(child, NS_cbc, PR_cbc + ':IdentificationCode', muhatap.UlkeKodu);
  AddChildNode(child, NS_cbc, PR_cbc + ':Name', muhatap.Ulke);
  // vergi dairesi
  child := CreateChildNode(node, NS_cac, PR_cac + ':PartyTaxScheme');
  child := CreateChildNode(child, NS_cac, PR_cac + ':TaxScheme');
  AddChildNode(child, NS_cbc, PR_cbc + ':Name', muhatap.VergiDairesi);
  // Contact
  child := CreateChildNode(node, NS_cac, PR_cac + ':Contact');
  AddChildNode(child, NS_cbc, PR_cbc + ':Telephone', '');
  AddChildNode(child, NS_cbc, PR_cbc + ':Telefax', '');
  AddChildNode(child, NS_cbc, PR_cbc + ':ElectronicMail', '');
  // �ah�s �irket sahibi
  if Length(muhatap.VKNTCKN) = 11 then
  begin
    child := CreateChildNode(node, NS_cac, PR_cac + ':Person');
    // Unvan ad-soyad tespiti
    i := LastDelimiter(' ', muhatap.Unvan);
    if i < 2 then
      raise Exception.Create('Unvan�n format� uygun de�il!');
    AddChildNode(child, NS_cbc, PR_cbc + ':FirstName',
      Copy(muhatap.Unvan, 0, i - 1));
    AddChildNode(child, NS_cbc, PR_cbc + ':FamilyName',
      Copy(muhatap.Unvan, i + 1, Length(muhatap.Unvan) - 2));
  end;
  // <cac:PartyName>
  // <cbc:Name>ISIS Bili�im</cbc:Name>
  // </cac:PartyName>
  // <cac:PostalAddress>
  // <cbc:Room/>
  // <cbc:StreetName/>
  // <cbc:BuildingName/>
  // <cbc:BuildingNumber/>
  // <cbc:CitySubdivisionName>Alsancak</cbc:CitySubdivisionName>
  // <cbc:CityName>�ZM�R</cbc:CityName>
  // <cbc:PostalZone/>
  // <cbc:Region/>
  // <cac:Country>
  // <cbc:Name>T�rkiye</cbc:Name>
  // </cac:Country>
  // </cac:PostalAddress>
  // <cac:PartyTaxScheme>
  // <cac:TaxScheme>
  // <cbc:Name/>
  // </cac:TaxScheme>
  // </cac:PartyTaxScheme>
  // <cac:Contact>
  // <cbc:Telephone/>
  // <cbc:Telefax/>
  // <cbc:ElectronicMail/>
  // </cac:Contact>
  // <cac:Person>
  // <cbc:FirstName/>
  // <cbc:FamilyName/>
  // </cac:Person>
end;

procedure KalemEkle(node: IXMLNode; kalem: TKalem; BelgePB: String);
var
  new: IXMLNode;
  child: IXMLNode;
  i: Integer;
begin
  new := node.OwnerDocument.CreateElement(PR_cac + ':InvoiceLine', NS_cac);

  // Kalem numaras�
  AddChildNode(new, NS_cbc, PR_cbc + ':ID', IntToStr(kalem.KalemNo));
  node.ChildNodes.Add(new);

  // notlar
  if kalem.Notlar <> nil then
    for i := 0 to kalem.Notlar.Count do
      AddChildNode(new, NS_cbc, PR_cbc + ':Note', kalem.Notlar[i]);

  // miktar
  child := CreateChildNode(new, NS_cbc, PR_cbc + ':InvoicedQuantity');
  child.Attributes['unitCode'] :=
    StringReplace(GetEnumName(TypeInfo(TOlcuBirimleri), Ord(kalem.OlcuBirimi)),
    '_', '', []);
  child.Text := FloatToStr(kalem.Miktar);

  // Kalem tutar�
  child := CreateChildNode(new, NS_cbc, PR_cbc + ':LineExtensionAmount');
  child.Attributes['currencyID'] := BelgePB;
  child.Text := FloatToStr(kalem.KalemTutar);

  // indirim

  // vergiler

  // Detay
  child := CreateChildNode(new, NS_cac, PR_cac + ':Item');
  AddChildNode(child, NS_cbc, PR_cbc + ':Name', kalem.UrunAdi);
  // birim fiyat
  child := CreateChildNode(new, NS_cac, PR_cac + ':Price');
  child := CreateChildNode(child, NS_cbc, PR_cbc + ':PriceAmount');
  child.Text := FloatToStr(kalem.BirimFiyat);
  child.Attributes['currencyID'] := BelgePB;
  // <cac:InvoiceLine>
  // <cbc:ID>1</cbc:ID>
  // <cbc:Note/>
  // <cbc:InvoicedQuantity unitCode="C62">1</cbc:InvoicedQuantity>
  // <cbc:LineExtensionAmount currencyID="TRL">500</cbc:LineExtensionAmount>
  // <cac:AllowanceCharge>
  // <cbc:ChargeIndicator>false</cbc:ChargeIndicator>
  // <cbc:Amount currencyID="TRL">0</cbc:Amount>
  // </cac:AllowanceCharge>
  // <cac:TaxTotal>
  // <cbc:TaxAmount currencyID="TRL">90</cbc:TaxAmount>
  // <cac:TaxSubtotal>
  // <cbc:TaxAmount currencyID="TRL">90</cbc:TaxAmount>
  // <cbc:Percent>18</cbc:Percent>
  // <cac:TaxCategory>
  // <cbc:TaxExemptionReason/>
  // <cac:TaxScheme>
  // <cbc:TaxTypeCode>0015</cbc:TaxTypeCode>
  // </cac:TaxScheme>
  // </cac:TaxCategory>
  // </cac:TaxSubtotal>
  // </cac:TaxTotal>
  // <cac:Item>
  // <cbc:Name>Test</cbc:Name>
  // </cac:Item>
  // <cac:Price>
  // <cbc:PriceAmount currencyID="TRL">500</cbc:PriceAmount>
  // </cac:Price>
  // </cac:InvoiceLine>
end;

end.
