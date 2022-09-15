-- Filtrar dependentes
select  c.nome colaborador, d.nome dependente, to_char (d.data_nascimento, 'DD-MM-YYYY') data_nascimento
from brh.dependente d
inner join brh.colaborador c
on c.matricula = d.colaborador
where d.nome like 'H%' or d.nome like '%h%' or to_char(d.data_nascimento, 'MM') in ('04', '05', '06')
order by c.nome, d.nome;

--Listar colaborador com maior salario
select nome, max (salario) 
from brh.colaborador
where salario = (select max(salario) from brh.colaborador)
group by nome;

--Relatorio de senioridade
select matricula, nome, salario,
case 
when salario <= 3000 then 'Junior'
when salario > 3000 and salario <= 6000 then 'Pleno'
when salario > 6000 and salario <= 20000 then 'Senior'
else 'Corpo diretor'
end as Senioridade
from brh.colaborador
order by senioridade, nome;

--Listar colaboradores em projetos

--UPDATE brh.projeto SET id = id - 4 WHERE nome != 'BI';

select d.nome DEPARTAMENTO, p.nome PROJETO, count (*)
from
brh.atribuicao a
inner join 
brh.projeto p
on a.projeto = p.id 
inner join
brh.colaborador c
on c.matricula = a.colaborador
inner join 
brh.departamento d
on c.departamento = d.sigla
group by d.nome , p.nome 
order by  d.nome,  p.nome;

--Listar colaboradores com mais dependentes
select c.nome COLABORADOR,  count (*) QUANTIDADE_DEPENDENTES
from
brh.colaborador c
inner join
brh.dependente d
on c.matricula = d.colaborador
group by c.nome
having count (*)> 1
order by quantidade_dependentes desc, c.nome;

--Listar faixa etária dos dependentes
select CPF,nome,data_nascimento,parentesco,colaborador, nvl(trunc((months_between(sysdate, data_nascimento)/12)), 0) as IDADE, 
case 
when nvl(trunc((months_between(sysdate, data_nascimento)/12)), 0) < 18 then 'Menor de Idade'
else 'Maior de Idade'
end as Faixa_Etaria
from brh.dependente
order by colaborador, nome;

--Opcional: Analisar necessidade de criar view
---View vw_plano_senioridade
create or replace view vw_plano_senioridade as
select matricula, nome, salario,
(case 
when salario <= 3000 then 'Junior'
when salario > 3000 and salario <= 6000 then 'Pleno'
when salario > 6000 and salario <= 20000 then 'Senior'
else 'Corpo diretor'
end) as Senioridade,
(case
when salario <= 3000 then salario * 0.01 
when salario > 3000 and salario <= 6000 then salario * 0.02
when salario > 6000 and salario <= 20000 then salario * 0.03
else salario * 0.05
end) as Mensalidade
from brh.colaborador
order by senioridade, nome;

---View Listar faixa etária dos dependentes
create or replace view vw_plano_idade_dependentes as
select CPF,nome,data_nascimento,parentesco,colaborador, nvl(trunc((months_between(sysdate, data_nascimento)/12)), 0) as IDADE, 
case 
when nvl(trunc((months_between(sysdate, data_nascimento)/12)), 0) < 18 then 'Menor de Idade'
else 'Maior de Idade'
end as Faixa_Etaria
from brh.dependente
order by colaborador, nome;

--Opcional: Relatório de plano de saúde
select colaborador,  vw_plano_senioridade.mensalidade + valor_dependente.total as a_pagar from
(
select colaborador, sum(acrescimo) as total
from
(
select colaborador, 
case
when parentesco = 'Cônjuge' then 100
when parentesco = 'Filho(a)'  and faixa_etaria = 'Maior de Idade' then 50
else 25
end as Acrescimo
from vw_plano_idade_dependentes 
)
group by colaborador
) valor_dependente
inner join 
vw_plano_senioridade
on vw_plano_senioridade.matricula = valor_dependente.colaborador
order by colaborador;

--Opcional: Paginar listagem de colaboradores
select * from 
(select rownum as linha, c.*
from brh.colaborador c
order by nome)
where linha >= 11 and linha <=20;


