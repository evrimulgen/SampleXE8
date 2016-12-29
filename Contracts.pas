unit Contracts;

interface

uses
  SysUtils, System.Classes, tr.com.isisbilisim.types;

type

  TMuhatap = class
  public
    { Public declarations }
    WebURI, VKNTCKN, Unvan, Ilce, Il, Ulke, UlkeKodu, VergiDairesi: String end;

    TFaturaSenaryo = (TEMELFATURA, TICARIFATURA, IHRACAT, YOLCUBERABERFATURA);
    TFaturaTipi = (SATIS, IADE, TEVKIFAT, ISTISNA, OZELMATRAH, IHRACKAYITLI);
    TOlcuBirimleri = (B32, // Kilogram / Metrekare
      BAS, // Bas
      BX, // Kutu
      C62, // Adet
      CCT, // Ton ba��na ta��ma kapasitesi
      CLT, // Santilitre
      CMK, // Santimetrekare
      CMQ, // Santimetrek�p
      CMT, // Santimetre
      CPR, // Adet (�ift)
      CS, // Koli
      CT, // Karton
      D30, // Br�t Kalori De�eri
      D40, // Bin Litre
      DAY, // G�n
      GMS, // G�m��
      GRM, // Gram
      GT, // Gross Ton
      HUR, // Saat
      K20, // Kg Potasyum Oksit
      K58, // Kurutulmu� Net A��rl�kl� kg
      K62, // Kg / Adet
      KGM, // Kilogram
      KGS, // KGS
      KH6, // Kg / Bas
      KJO, // Kilojul
      KPR, // Kilogram-�ift
      KSD, // %90 Kuru �r�n Kilogram�
      KTM, // Kilometre
      KWH, // Kilowattsaat
      KWT, // Kilowatt
      LPA, // Saf Alkol Listesi
      LTR, // Litre
      MLT, // Mililitre
      MMQ, // Metrek�p
      MMT, // Milimetre
      MON, // Ay
      MTK, // Metrekare
      MTQ, // Metrek�p
      MTR, // Metre
      NCL, // H�cre Adet
      NCR, // Karat
      NM3, // 101325 mbar/m� (0�C)
      PA, // Paket
      PR, // �ift
      R9, // Bin Metrek�p
      _SET, // Set
      SM3, // 101325 mbar/m� (15�C)
      T3, // Bin Adet
      TWH, // Bin Kilowatt-saat
      _26 // Ton
      );

    TVergi = class
    public
      Matrah: Nullable<Currency>;
      Kodu: String;
      Adi: String;
      Oran: Nullable<Double>;
      Tutar: Currency;
      MuafiyetKodu: String;
      MuafiyetAciklama: String;
      constructor Create(kodu, adi: String);
    end;

  TKalem = class
  public
    { Public declarations }
    KalemNo: Integer;
    Notlar: TStringList;
    Miktar: Double;
    OlcuBirimi: TOlcuBirimleri;
    IndirimTutar: Nullable<Currency>;
    KalemTutar: Currency;
    UrunAdi: String;
    BirimFiyat: Currency;
    KDV: TVergi;
    OTV: TVergi;
    ToplamVergi: Currency;
  end;

  TKalemler = class(TList)
  private
    function Get(Index: Integer): TKalem;
  public
    destructor Destroy; override;
    function Add(Value: TKalem): Integer;
    property Items[Index: Integer]: TKalem read Get; default;
  end;

  TFatura = class
  private
    { Private declarations }
  public
    { Public declarations }
    Senaryo: TFaturaSenaryo;
    Tipi: TFaturaTipi;
    BelgePB: String;
    Alici: TMuhatap;
    Kalemler: TKalemler;
    KalemToplamTutar: Currency;
    VergiDahilTutar: Currency;
    VergiHaricTutar: Currency;
    ToplamIndirim: Currency;
    OdenecekTutar: Currency;
  end;

implementation

constructor TVergi.Create(kodu, adi: String);
begin
  self.Kodu := kodu;
  self.Adi := adi;
end;

function TKalemler.Add(Value: TKalem): Integer;
begin
  Result := inherited Add(Value);
end;

destructor TKalemler.Destroy;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    Items[i].Free;
  inherited;
end;

function TKalemler.Get(Index: Integer): TKalem;
begin
  Result := TKalem(inherited Get(Index));
end;

end.
