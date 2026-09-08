import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { PeopleService } from './people.service';
import { I18nService } from './i18n.service';

describe('PeopleService', () => {
  let service: PeopleService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient()],
    });
    service = TestBed.inject(PeopleService);
  });

  it('falls back when the directory has no match', () => {
    const i18n = TestBed.inject(I18nService);
    expect(service.nameOf(42)).toBe(i18n.t('common.collaboratorN', { id: 42 }));
    expect(service.initialsOf(42)).toBe('?');
    expect(service.jobTitleOf(42)).toBeNull();
  });

  it('maps a user to a team member', () => {
    const member = service.toMember({
      id: 1,
      email: 'a@rh.local',
      role: 'employee',
      team_id: null,
      business_unit_id: null,
      project_id: null,
      first_name: 'Ada',
      last_name: 'Lovelace',
      job_title: 'Dev',
    });
    expect(member.first_name).toBe('Ada');
    expect(member.job_title).toBe('Dev');
  });
});
