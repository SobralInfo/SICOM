unit untFiltrarLancFinanceiros;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Mask, Vcl.Buttons,
  Vcl.Imaging.pngimage, Vcl.ExtCtrls, unitConfiguracoes, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt,
  Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client;

type
  TfrmFiltrarLancFinanceiros = class(TForm)
    Panel3: TPanel;
    Label2: TLabel;
    Image1: TImage;
    spbPesquisar: TSpeedButton;
    edtClienteFornecedor: TEdit;
    rdbCliente: TRadioButton;
    rdbFornecedor: TRadioButton;
    cbbStatus: TComboBox;
    Label1: TLabel;
    Image3: TImage;
    Image4: TImage;
    Image2: TImage;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    qryAUX: TFDQuery;
    GroupBox1: TGroupBox;
    rdbEntrada: TRadioButton;
    mkeDtIni: TMaskEdit;
    mkeDtFim: TMaskEdit;
    Label4: TLabel;
    rdbVencimento: TRadioButton;
    Label3: TLabel;
    cbbTipo: TComboBox;
    SpeedButton1: TSpeedButton;
    edtContaFinanceira: TEdit;
    Label5: TLabel;
    procedure Image1Click(Sender: TObject);
    procedure Image4Click(Sender: TObject);
    procedure Image3Click(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure spbPesquisarClick(Sender: TObject);
    procedure edtClienteFornecedorKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure SpeedButton1Click(Sender: TObject);
    procedure edtContaFinanceiraKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    idClienteFornecedor, idContaFinanceira: integer;
    receita, despesa, saldo: double;
    procedure Confirmar;
  end;

var
  frmFiltrarLancFinanceiros: TfrmFiltrarLancFinanceiros;

implementation

{$R *.dfm}

uses untConsultarLancFinanceiros, untPesquisarClientes,
  untPesquisarFornecedores, untPesquisarContasFinanceiras;

procedure TfrmFiltrarLancFinanceiros.Confirmar;
begin
   try
      StrToDate(mkeDtIni.Text);
   except
      prcMsgAdv('Data inicial vencimento inválida.');
      exit;
   end;

   try
      StrToDate(mkeDtIni.Text);
   except
      prcMsgAdv('Data final vencimento inválida.');
      exit;
   end;

   frmConsultarLancFinanceiros.qryListagem.Close;
   frmConsultarLancFinanceiros.qryListagem.SQL.Clear;
   frmConsultarLancFinanceiros.qryListagem.SQL.Add(' Select lf.*, ');
   frmConsultarLancFinanceiros.qryListagem.SQL.Add('        cf.descricao as contaFinanceira, fp.nome as formaPagto, ');
   frmConsultarLancFinanceiros.qryListagem.SQL.Add('        case when lf.tipo_lancamento = ''R'' then ''RECEITA'' else ''DESPESA'' end as tipoLancamento ');
   frmConsultarLancFinanceiros.qryListagem.SQL.Add('   from lancamentos_financeiros lf inner join contas_financeiras cf on lf.id_conta_financeira = cf.id ');
   frmConsultarLancFinanceiros.qryListagem.SQL.Add('                                   left join FORMAS_PAGAMENTO fp on lf.id_forma_pagto = fp.id ');
   frmConsultarLancFinanceiros.qryListagem.SQL.Add('  where 1 = 1 ');

   if cbbStatus.ItemIndex > 0 then
     begin
       if rdbVencimento.Checked then begin
         case cbbStatus.ItemIndex of
            1: frmConsultarLancFinanceiros.qryListagem.SQL.Add(' and ((lf.status = ''A'') and (data_vencimento >= :dtVenc)) ');
            2: frmConsultarLancFinanceiros.qryListagem.SQL.Add(' and ((lf.status = ''A'') and (data_vencimento < :dtVenc)) ');
            3: frmConsultarLancFinanceiros.qryListagem.SQL.Add(' and lf.status = ''P'' ');
            4: frmConsultarLancFinanceiros.qryListagem.SQL.Add(' and lf.status = ''C'' ');
            5: frmConsultarLancFinanceiros.qryListagem.SQL.Add(' and (((lf.status = ''A'') and (DATA_ENTRADA >= :DATA_ENTRADA)) or ' +
                                                                   '  ((lf.status = ''A'') and (DATA_ENTRADA < :DATA_ENTRADA))) ');
         end;
         if cbbStatus.ItemIndex <= 2 then
            frmConsultarLancFinanceiros.qryListagem.Params.ParamByName('dtVenc').AsDate := date;
       end else begin
         case cbbStatus.ItemIndex of
            1: frmConsultarLancFinanceiros.qryListagem.SQL.Add(' and ((lf.status = ''A'') and (DATA_ENTRADA >= :DATA_ENTRADA)) ');
            2: frmConsultarLancFinanceiros.qryListagem.SQL.Add(' and ((lf.status = ''A'') and (DATA_ENTRADA < :DATA_ENTRADA)) ');
            3: frmConsultarLancFinanceiros.qryListagem.SQL.Add(' and lf.status = ''P'' ');
            4: frmConsultarLancFinanceiros.qryListagem.SQL.Add(' and lf.status = ''C'' ');
            5: frmConsultarLancFinanceiros.qryListagem.SQL.Add(' and (((lf.status = ''A'') and (DATA_ENTRADA >= :DATA_ENTRADA)) or ' +
                                                                   '  ((lf.status = ''A'') and (DATA_ENTRADA < :DATA_ENTRADA))) ');
         end;
         if ((cbbStatus.ItemIndex <= 2) or (cbbStatus.ItemIndex = 5)) then
            frmConsultarLancFinanceiros.qryListagem.Params.ParamByName('DATA_ENTRADA').AsDate := date;
       end;
     end;

   if cbbTipo.ItemIndex > 0 then
      frmConsultarLancFinanceiros.qryListagem.SQL.Add(' and lf.tipo_lancamento = ' + QuotedStr(copy(cbbTipo.Text,1,1)) );

   if rdbVencimento.Checked then
      frmConsultarLancFinanceiros.tipoData := 'V'
   else
      frmConsultarLancFinanceiros.tipoData := 'E';

   if idContaFinanceira > 0 then
      frmConsultarLancFinanceiros.qryListagem.SQL.Add(' and lf.id_conta_financeira = ' + idcontafinanceira.ToString );

   if idClienteFornecedor > 0 then
      begin
         if rdbCliente.Checked then
            frmConsultarLancFinanceiros.qryListagem.SQL.Add(' and lf.ID_CLIENTE_FORNECEDOR = ' + idClienteFornecedor.ToString + ' and lf.TIPO_CLIENTE_FORNECEDOR = ''C'' ')
         else
            frmConsultarLancFinanceiros.qryListagem.SQL.Add(' and lf.ID_CLIENTE_FORNECEDOR = ' + idClienteFornecedor.ToString + ' and lf.TIPO_CLIENTE_FORNECEDOR = ''F'' ');
      end;

   if rdbVencimento.Checked then begin
      frmConsultarLancFinanceiros.lblTipoData.Caption := 'Data Vencimento:';
      frmConsultarLancFinanceiros.qryListagem.SQL.Add(' and lf.data_vencimento between :dtIni and :dtFim ');
      frmConsultarLancFinanceiros.qryListagem.SQL.Add(' order by data_vencimento ');
   end
   else
   begin
      frmConsultarLancFinanceiros.lblTipoData.Caption := 'Data de Entrada:';
      frmConsultarLancFinanceiros.qryListagem.SQL.Add(' and lf.DATA_ENTRADA between :dtIni and :dtFim ');
      frmConsultarLancFinanceiros.qryListagem.SQL.Add(' order by DATA_ENTRADA ');
   end;

   frmConsultarLancFinanceiros.qryListagem.Params.ParamByName('dtIni').AsDate := strtodate(mkeDtIni.Text);
   frmConsultarLancFinanceiros.qryListagem.Params.ParamByName('dtFim').AsDate := strtodate(mkeDtFim.Text);

   frmConsultarLancFinanceiros.qryListagem.Open;

   receita := 0.00;
   despesa := 0.00;

   while not frmConsultarLancFinanceiros.qryListagem.Eof do begin
      if frmConsultarLancFinanceiros.qryListagemTIPO_LANCAMENTO.AsString = 'R' then
         receita := receita + frmConsultarLancFinanceiros.qryListagemVALOR_DOCUMENTO.AsFloat
      else
         despesa := despesa + frmConsultarLancFinanceiros.qryListagemVALOR_DOCUMENTO.AsFloat;
      frmConsultarLancFinanceiros.qryListagem.Next;
   end;

   frmConsultarLancFinanceiros.qryListagem.First;

   saldo := receita - despesa;

   frmConsultarLancFinanceiros.lblTotalReceitas.Caption := FormatFloat('###,#0.00', receita);
   frmConsultarLancFinanceiros.lblTotalDespesas.Caption := FormatFloat('###,#0.00', despesa);
   frmConsultarLancFinanceiros.lblSaldo.Caption := FormatFloat('###,#0.00', saldo);

   frmConsultarLancFinanceiros.dtFiltroIni := strtodate(mkeDtIni.Text);
   frmConsultarLancFinanceiros.dtFiltroFim := strtodate(mkeDtFim.Text);
   frmConsultarLancFinanceiros.lblFiltroClienteFornecedor.Caption := Trim(edtClienteFornecedor.Text);
   frmConsultarLancFinanceiros.idClienteFornecedor := idClienteFornecedor;
   frmConsultarLancFinanceiros.lblFiltrosPeriodo.Caption := mkeDtIni.Text + ' à ' + mkeDtFim.Text;
   frmConsultarLancFinanceiros.lblStatus.caption := trim(cbbStatus.Text);
   frmConsultarLancFinanceiros.idStatus := cbbStatus.ItemIndex;
   frmConsultarLancFinanceiros.idTipo := cbbTipo.ItemIndex;
   frmConsultarLancFinanceiros.lblTipo.Caption := Trim(cbbTipo.Text);
   frmConsultarLancFinanceiros.idcontafinanceira := idContaFinanceira;
   frmConsultarLancFinanceiros.lblConta.Caption := trim(edtContaFinanceira.Text);

   if rdbCliente.Checked then
      begin
         frmConsultarLancFinanceiros.tipoClienteFornecedor := 'C';
      end
   else
      begin
         frmConsultarLancFinanceiros.tipoClienteFornecedor := 'F';
      end;

   close;
end;

procedure TfrmFiltrarLancFinanceiros.edtClienteFornecedorKeyDown(
  Sender: TObject; var Key: Word; Shift: TShiftState);
begin
   if key = VK_DELETE then
      begin
        idClienteFornecedor := 0;
        edtClienteFornecedor.Text := 'TODOS';
      end;
end;

procedure TfrmFiltrarLancFinanceiros.edtContaFinanceiraKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
   if key = VK_DELETE then
      begin
        idContaFinanceira := 0;
        edtContaFinanceira.Text := 'TODAS';
      end;
end;

procedure TfrmFiltrarLancFinanceiros.FormCreate(Sender: TObject);
begin
   idContaFinanceira := 0;
   idClienteFornecedor := 0;
end;

procedure TfrmFiltrarLancFinanceiros.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
   case key of
      VK_ESCAPE: close;
      VK_F12: Confirmar;
   end;
end;

procedure TfrmFiltrarLancFinanceiros.Image1Click(Sender: TObject);
begin
   close;
end;

procedure TfrmFiltrarLancFinanceiros.Image3Click(Sender: TObject);
begin
   Confirmar;
end;

procedure TfrmFiltrarLancFinanceiros.Image4Click(Sender: TObject);
begin
   close;
end;

procedure TfrmFiltrarLancFinanceiros.spbPesquisarClick(Sender: TObject);
begin
   if rdbCliente.Checked then
      begin
         Application.CreateForm(TfrmPesquisarClientes, frmPesquisarClientes);
         frmPesquisarClientes.origem := 'FILTRO_LANC_FINANCEIRO';
         frmPesquisarClientes.ShowModal;
      end
   else
      begin
         Application.CreateForm(TfrmPesquisarFornecedores, frmPesquisarFornecedores);
         frmPesquisarFornecedores.origem := 'FILTRO_LANC_FINANCEIRO';
         frmPesquisarFornecedores.ShowModal;
      end;
end;

procedure TfrmFiltrarLancFinanceiros.SpeedButton1Click(Sender: TObject);
begin
   Application.CreateForm(TfrmPesquisarContasFinanceiras, frmPesquisarContasFinanceiras);
   frmPesquisarContasFinanceiras.qryContasFinanceiras.Close;
   frmPesquisarContasFinanceiras.qryContasFinanceiras.Open;
   frmPesquisarContasFinanceiras.origem := 'LANC_FINANCEIRO';
   frmPesquisarContasFinanceiras.showmodal;
end;

end.
